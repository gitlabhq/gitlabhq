# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class Fog
      def available?
        object_store.enabled
      end

      def data(model)
        files.get(key(model))&.body
      rescue Excon::Error::NotFound
        # If the object does not exist in the object storage, this method returns nil.
      end

      def set_data(model, new_data)
        if Feature.enabled?(:ci_live_trace_use_fog_attributes)
          files.create(create_attributes(model, new_data))
        else
          # TODO: Support AWS S3 server side encryption
          files.create({
            key: key(model),
            body: new_data
          })
        end
      end

      def append_data(model, new_data, offset)
        if offset > 0
          truncated_data = data(model).to_s.byteslice(0, offset)
          new_data = truncated_data + new_data
        end

        set_data(model, new_data)
        new_data.bytesize
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

        @connection ||= ::Fog::Storage.new(object_store.connection.to_hash.deep_symbolize_keys)
      end

      def fog_directory
        @fog_directory ||= connection.directories.new(key: bucket_name)
      end

      def files
        @files ||= fog_directory.files
      end

      def object_store
        Gitlab.config.artifacts.object_store
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
