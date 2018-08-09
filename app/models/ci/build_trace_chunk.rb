# frozen_string_literal: true

module Ci
  class BuildTraceChunk < ActiveRecord::Base
    include FastDestroyAll
    include ::Gitlab::ExclusiveLeaseHelpers
    extend Gitlab::Ci::Model

    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id

    default_value_for :data_store, :redis

    CHUNK_SIZE = 128.kilobytes
    WRITE_LOCK_RETRY = 10
    WRITE_LOCK_SLEEP = 0.01.seconds
    WRITE_LOCK_TTL = 1.minute

    # Note: The ordering of this enum is related to the precedence of persist store.
    # The bottom item takes the higest precedence, and the top item takes the lowest precedence.
    enum data_store: {
      redis: 1,
      database: 2,
      fog: 3
    }

    class << self
      def all_stores
        @all_stores ||= self.data_stores.keys
      end

      def persistable_store
        # get first available store from the back of the list
        all_stores.reverse.find { |store| get_store_class(store).available? }
      end

      def get_store_class(store)
        @stores ||= {}
        @stores[store] ||= "Ci::BuildTraceChunks::#{store.capitalize}".constantize.new
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
    end

    ##
    # Data is memoized for optimizing #size and #end_offset
    def data
      @data ||= get_data.to_s
    end

    def truncate(offset = 0)
      raise ArgumentError, 'Offset is out of range' if offset > size || offset < 0
      return if offset == size # Skip the following process as it doesn't affect anything

      self.append("", offset)
    end

    def append(new_data, offset)
      raise ArgumentError, 'New data is missing' unless new_data
      raise ArgumentError, 'Offset is out of range' if offset > size || offset < 0
      raise ArgumentError, 'Chunk size overflow' if CHUNK_SIZE < (offset + new_data.bytesize)

      in_lock(*lock_params) do # Write opetation is atomic
        unsafe_set_data!(data.byteslice(0, offset) + new_data)
      end

      schedule_to_persist if full?
    end

    def size
      data&.bytesize.to_i
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

    def persist_data!
      in_lock(*lock_params) do # Write opetation is atomic
        unsafe_persist_to!(self.class.persistable_store)
      end
    end

    private

    def unsafe_persist_to!(new_store)
      return if data_store == new_store.to_s
      raise ArgumentError, 'Can not persist empty data' unless size > 0

      old_store_class = self.class.get_store_class(data_store)

      get_data.tap do |the_data|
        self.raw_data = nil
        self.data_store = new_store
        unsafe_set_data!(the_data)
      end

      old_store_class.delete_data(self)
    end

    def get_data
      self.class.get_store_class(data_store).data(self)&.force_encoding(Encoding::BINARY) # Redis/Database return UTF-8 string as default
    rescue Excon::Error::NotFound
      # If the data store is :fog and the file does not exist in the object storage, this method returns nil.
    end

    def unsafe_set_data!(value)
      raise ArgumentError, 'New data size exceeds chunk size' if value.bytesize > CHUNK_SIZE

      self.class.get_store_class(data_store).set_data(self, value)
      @data = value

      save! if changed?
    end

    def schedule_to_persist
      return if data_persisted?

      Ci::BuildTraceChunkFlushWorker.perform_async(id)
    end

    def data_persisted?
      !redis?
    end

    def full?
      size == CHUNK_SIZE
    end

    def lock_params
      ["trace_write:#{build_id}:chunks:#{chunk_index}",
       { ttl: WRITE_LOCK_TTL,
         retries: WRITE_LOCK_RETRY,
         sleep_sec: WRITE_LOCK_SLEEP }]
    end
  end
end
