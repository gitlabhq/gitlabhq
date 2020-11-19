# frozen_string_literal: true

module Ci
  class BuildTraceChunk < ApplicationRecord
    extend ::Gitlab::Ci::Model
    include ::Comparable
    include ::FastDestroyAll
    include ::Checksummable
    include ::Gitlab::ExclusiveLeaseHelpers
    include ::Gitlab::OptimisticLocking

    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    default_value_for :data_store, :redis

    after_create { metrics.increment_trace_operation(operation: :chunked) }

    CHUNK_SIZE = 128.kilobytes
    WRITE_LOCK_RETRY = 10
    WRITE_LOCK_SLEEP = 0.01.seconds
    WRITE_LOCK_TTL = 1.minute

    FailedToPersistDataError = Class.new(StandardError)

    # Note: The ordering of this hash is related to the precedence of persist store.
    # The bottom item takes the highest precedence, and the top item takes the lowest precedence.
    DATA_STORES = {
      redis: 1,
      database: 2,
      fog: 3
    }.freeze

    STORE_TYPES = DATA_STORES.keys.map do |store|
      [store, "Ci::BuildTraceChunks::#{store.capitalize}".constantize]
    end.to_h.freeze

    enum data_store: DATA_STORES

    scope :live, -> { redis }
    scope :persisted, -> { not_redis.order(:chunk_index) }

    class << self
      def all_stores
        STORE_TYPES.keys
      end

      def persistable_store
        # get first available store from the back of the list
        all_stores.reverse.find { |store| get_store_class(store).available? }
      end

      def get_store_class(store)
        store = store.to_sym

        raise "Unknown store type: #{store}" unless STORE_TYPES.key?(store)

        STORE_TYPES[store].new
      end

      ##
      # FastDestroyAll concerns
      def begin_fast_destroy
        all_stores.each_with_object({}) do |store, result|
          relation = public_send(store) # rubocop:disable GitlabSecurity/PublicSend
          keys = get_store_class(store).keys(relation)

          result[store] = keys if keys.present?
        end
      end

      ##
      # FastDestroyAll concerns
      def finalize_fast_destroy(keys)
        keys.each do |store, value|
          get_store_class(store).delete_keys(value)
        end
      end

      ##
      # Sometimes we do not want to read raw data. This method makes it easier
      # to find attributes that are just metadata excluding raw data.
      #
      def metadata_attributes
        attribute_names - %w[raw_data]
      end
    end

    def data
      @data ||= get_data.to_s
    end

    def crc32
      checksum.to_i
    end

    def truncate(offset = 0)
      raise ArgumentError, 'Offset is out of range' if offset > size || offset < 0
      return if offset == size # Skip the following process as it doesn't affect anything

      self.append("", offset)
    end

    def append(new_data, offset)
      raise ArgumentError, 'New data is missing' unless new_data
      raise ArgumentError, 'Offset is out of range' if offset < 0 || offset > size
      raise ArgumentError, 'Chunk size overflow' if CHUNK_SIZE < (offset + new_data.bytesize)

      in_lock(lock_key, **lock_params) { unsafe_append_data!(new_data, offset) }

      schedule_to_persist! if full?
    end

    def size
      @size ||= @data&.bytesize || current_store.size(self) || data&.bytesize
    end

    def start_offset
      chunk_index * CHUNK_SIZE
    end

    def end_offset
      start_offset + size
    end

    def range
      (start_offset...end_offset)
    end

    def schedule_to_persist!
      return if flushed?

      Ci::BuildTraceChunkFlushWorker.perform_async(id)
    end

    ##
    # It is possible that we run into two concurrent migrations. It might
    # happen that a chunk gets migrated after being loaded by another worker
    # but before the worker acquires a lock to perform the migration.
    #
    # We are using Redis locking to ensure that we perform this operation
    # inside an exclusive lock, but this does not prevent us from running into
    # race conditions related to updating a model representation in the
    # database. Optimistic locking is another mechanism that help here.
    #
    # We are using optimistic locking combined with Redis locking to ensure
    # that a chunk gets migrated properly.
    #
    # We are using until_executed deduplication strategy for workers,
    # which should prevent duplicated workers running in parallel for the same build trace,
    # and causing an exception related to an exclusive lock not being
    # acquired
    #
    def persist_data!
      in_lock(lock_key, **lock_params) do # exclusive Redis lock is acquired first
        raise FailedToPersistDataError, 'Modifed build trace chunk detected' if has_changes_to_save?

        self.reset.then do |chunk|     # we ensure having latest lock_version
          chunk.unsafe_persist_data!   # we migrate the data and update data store
        end
      end
    rescue FailedToObtainLockError
      metrics.increment_trace_operation(operation: :stalled)

      raise FailedToPersistDataError, 'Data migration failed due to a worker duplication'
    rescue ActiveRecord::StaleObjectError
      raise FailedToPersistDataError, <<~MSG
        Data migration race condition detected

        store: #{data_store}
        build: #{build.id}
        index: #{chunk_index}
      MSG
    end

    ##
    # Build trace chunk is final (the last one that we do not expect to ever
    # become full) when a runner submitted a build pending state and there is
    # no chunk with higher index in the database.
    #
    def final?
      build.pending_state.present? && chunks_max_index == chunk_index
    end

    def flushed?
      !redis?
    end

    def migrated?
      flushed?
    end

    def live?
      redis?
    end

    def <=>(other)
      return unless self.build_id == other.build_id

      self.chunk_index <=> other.chunk_index
    end

    protected

    def get_data
      # Redis / database return UTF-8 encoded string by default
      current_store.data(self)&.force_encoding(Encoding::BINARY)
    end

    def unsafe_persist_data!(new_store = self.class.persistable_store)
      return if data_store == new_store.to_s

      current_data = data
      old_store_class = current_store
      current_size = current_data&.bytesize.to_i

      unless current_size == CHUNK_SIZE || final?
        raise FailedToPersistDataError, <<~MSG
          data is not fulfilled in a bucket

          size: #{current_size}
          state: #{pending_state?}
          max: #{chunks_max_index}
          index: #{chunk_index}
        MSG
      end

      self.raw_data = nil
      self.data_store = new_store
      self.checksum = self.class.crc32(current_data)

      ##
      # We need to so persist data then save a new store identifier before we
      # remove data from the previous store to make this operation
      # trasnaction-safe. `unsafe_set_data! calls `save!` because of this
      # reason.
      #
      # TODO consider using callbacks and state machine to remove old data
      #
      unsafe_set_data!(current_data)

      old_store_class.delete_data(self)
    end

    def unsafe_set_data!(value)
      raise ArgumentError, 'New data size exceeds chunk size' if value.bytesize > CHUNK_SIZE

      current_store.set_data(self, value)

      @data = value
      @size = value.bytesize

      save! if changed?
    end

    def unsafe_append_data!(value, offset)
      new_size = value.bytesize + offset

      if new_size > CHUNK_SIZE
        raise ArgumentError, 'New data size exceeds chunk size'
      end

      current_store.append_data(self, value, offset).then do |stored|
        metrics.increment_trace_operation(operation: :appended)

        raise ArgumentError, 'Trace appended incorrectly' if stored != new_size
      end

      @data = nil
      @size = new_size

      save! if changed?
    end

    def full?
      size == CHUNK_SIZE
    end

    private

    def pending_state?
      build.pending_state.present?
    end

    def current_store
      self.class.get_store_class(data_store)
    end

    def chunks_max_index
      build.trace_chunks.maximum(:chunk_index).to_i
    end

    def lock_key
      "trace_write:#{build_id}:chunks:#{chunk_index}"
    end

    def lock_params
      {
        ttl: WRITE_LOCK_TTL,
        retries: WRITE_LOCK_RETRY,
        sleep_sec: WRITE_LOCK_SLEEP
      }
    end

    def metrics
      @metrics ||= ::Gitlab::Ci::Trace::Metrics.new
    end
  end
end
