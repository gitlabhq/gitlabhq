# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class Fog
      def self.available?
        object_store.enabled
      end

      def self.object_store
        Gitlab.config.artifacts.object_store
      end

      def available?
        self.class.available?
      end

      def data(model)
        files.get(key(model))&.body
      rescue Excon::Error::NotFound
        # If the object does not exist in the object storage, this method returns nil.
      end

      def set_data(model, new_data)
        files.create(create_attributes(model, new_data))
      end

      # This is the sequence that causes append_data to be called:
      #
      # 1. Runner sends a PUT /api/v4/jobs/:id to indicate the job is canceled or finished.
      # 2. UpdateBuildStateService#accept_build_state! persists all live job logs to object storage (or filesystem).
      # 3. UpdateBuildStateService#accept_build_state! returns a 202 to the runner.
      # 4. The runner continues to send PATCH requests with job logs until all logs have been sent and received.
      # 5. If the last PATCH request arrives after the job log has been persisted, we
      #    retrieve the data from object storage to append the remaining lines.
      def append_data(model, new_data, offset)
        if offset > 0
          truncated_data = data(model).to_s.byteslice(0, offset)
          new_data = append_strings(truncated_data, new_data)
        end

        set_data(model, new_data)
        new_data.bytesize
      rescue Encoding::CompatibilityError => e
        Gitlab::ErrorTracking.track_and_raise_exception(
          e,
          build_id: model.build_id,
          chunk_index: model.chunk_index,
          chunk_start_offset: model.start_offset,
          chunk_end_offset: model.end_offset,
          chunk_size: model.size,
          chunk_data_store: model.data_store,
          offset: offset,
          old_data_encoding: truncated_data.encoding.to_s,
          new_data: new_data,
          new_data_size: new_data.bytesize,
          new_data_encoding: new_data.encoding.to_s)
      end

      def size(model)
        data(model).to_s.bytesize
      end

      def delete_data(model)
        delete_keys([[model.build_id, model.chunk_index]])
      end

      def keys(relation)
        return [] unless available?

        relation.pluck(:build_id, :chunk_index)
      end

      def delete_keys(keys)
        keys.each do |key|
          files.destroy(key_raw(*key))
        end
      end

      private

      def append_strings(old_data, new_data)
        # When object storage is in use, old_data may be retrieved in UTF-8.
        old_data = old_data.force_encoding(Encoding::ASCII_8BIT)
        # new_data should already be in ASCII-8BIT, but just in case it isn't, do this.
        new_data = new_data.force_encoding(Encoding::ASCII_8BIT)

        old_data + new_data
      end

      def key(model)
        key_raw(model.build_id, model.chunk_index)
      end

      def create_attributes(model, new_data)
        {
          key: key(model),
          body: new_data
        }.merge(object_store_config.fog_attributes)
      end

      def key_raw(build_id, chunk_index)
        "tmp/builds/#{build_id.to_i}/chunks/#{chunk_index.to_i}.log"
      end

      def bucket_name
        return unless available?

        object_store.remote_directory
      end

      def connection
        return unless available?

        ::Gitlab::SafeRequestStore.fetch(object_store_raw_config) do
          ::Fog::Storage.new(object_store.connection.to_hash.deep_symbolize_keys)
        end
      end

      def fog_directory
        @fog_directory ||= connection.directories.new(key: bucket_name)
      end

      def files
        @files ||= fog_directory.files
      end

      def object_store
        self.class.object_store
      end

      def object_store_raw_config
        object_store
      end

      def object_store_config
        @object_store_config ||= ::ObjectStorage::Config.new(object_store_raw_config)
      end
    end
  end
end
