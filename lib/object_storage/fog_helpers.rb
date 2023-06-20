# frozen_string_literal: true

module ObjectStorage
  module FogHelpers
    include ::Gitlab::Utils::StrongMemoize

    def available?
      object_store.enabled
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

    def storage_location_identifier
      raise NotImplementedError, "#{self} does not implement #{__method__}"
    end

    def object_store
      ObjectStorage::Config::LOCATIONS.fetch(storage_location_identifier).object_store
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

      ::Fog::Storage.new(object_store.connection.to_hash.deep_symbolize_keys)
    end
    strong_memoize_attr :connection
  end
end
