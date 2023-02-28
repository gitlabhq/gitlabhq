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
      keys.each { |key| delete_object(key) }
    end

    private

    def delete_object(key)
      return unless available?

      connection.delete_object(bucket_name, object_key(key))

    # So far, only GoogleCloudStorage raises an exception when the file is not found.
    # Other providers support idempotent requests and does not raise an error
    # when the file is missing.
    rescue ::Google::Apis::ClientError => e
      Gitlab::ErrorTracking.log_exception(e)
    end

    def object_store
      Gitlab.config.uploads.object_store
    end

    def bucket_name
      object_store.remote_directory
    end

    def object_key(key)
      # We allow administrators to create "sub buckets" by setting a prefix.
      # This makes it possible to deploy GitLab with only one object storage
      # bucket. This mirrors the implementation in app/uploaders/object_storage.rb.
      File.join([object_store.bucket_prefix, key].compact)
    end

    def connection
      return unless available?

      strong_memoize(:connection) do
        ::Fog::Storage.new(object_store.connection.to_hash.deep_symbolize_keys)
      end
    end
  end
end
