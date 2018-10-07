# frozen_string_literal: true

module Uploads
  class Fog < Base
    include ::Gitlab::Utils::StrongMemoize

    def available?
      object_store.enabled
    end

    def keys(relation)
      return [] unless available?

      relation.pluck(:path)
    end

    def delete_keys(keys)
      keys.each do |key|
        connection.delete_object(bucket_name, key)
      end
    end

    private

    def object_store
      Gitlab.config.uploads.object_store
    end

    def bucket_name
      return unless available?

      object_store.remote_directory
    end

    def connection
      return unless available?

      strong_memoize(:connection) do
        ::Fog::Storage.new(object_store.connection.to_hash.deep_symbolize_keys)
      end
    end
  end
end
