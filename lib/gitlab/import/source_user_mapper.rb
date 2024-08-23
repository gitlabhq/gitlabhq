# frozen_string_literal: true

module Gitlab
  module Import
    class SourceUserMapper
      include Gitlab::ExclusiveLeaseHelpers

      LRU_CACHE_SIZE = 8000

      def initialize(namespace:, import_type:, source_hostname:)
        @namespace = namespace.root_ancestor
        @import_type = import_type
        @source_hostname = source_hostname
      end

      def find_source_user(source_user_identifier)
        cache_from_request_store[source_user_identifier] ||= ::Import::SourceUser.find_source_user(
          source_user_identifier: source_user_identifier,
          namespace: namespace,
          source_hostname: source_hostname,
          import_type: import_type
        )
      end

      def find_or_create_source_user(source_name:, source_username:, source_user_identifier:)
        source_user = find_source_user(source_user_identifier)

        return source_user if source_user

        source_user = create_source_user(
          source_name: source_name,
          source_username: source_username,
          source_user_identifier: source_user_identifier
        )

        cache_from_request_store[source_user_identifier] = source_user
      end

      private

      attr_reader :namespace, :import_type, :source_hostname

      def cache_from_request_store
        Gitlab::SafeRequestStore[:source_user_cache] ||= LruRedux::Cache.new(LRU_CACHE_SIZE)
      end

      def create_source_user(source_name:, source_username:, source_user_identifier:)
        in_lock(lock_key(source_user_identifier), sleep_sec: 2.seconds) do |retried|
          if retried
            source_user = find_source_user(source_user_identifier)
            next source_user if source_user
          end

          create_source_user_mapping(source_name, source_username, source_user_identifier)
        end
      end

      def create_source_user_mapping(source_name, source_username, source_user_identifier)
        ::Import::SourceUser.transaction do
          import_source_user = ::Import::SourceUser.new(
            namespace: namespace,
            import_type: import_type,
            source_username: source_username,
            source_name: source_name,
            source_user_identifier: source_user_identifier,
            source_hostname: source_hostname
          )

          import_source_user.placeholder_user = create_placeholder_user(source_name, source_username)
          import_source_user.save!
          import_source_user
        end
      end

      def create_placeholder_user(source_name, source_username)
        return namespace_import_user if placeholder_user_limit_exceeded?

        Gitlab::Import::PlaceholderUserCreator.new(
          import_type: import_type,
          source_hostname: source_hostname,
          source_name: source_name,
          source_username: source_username,
          namespace: namespace
        ).execute
      end

      def namespace_import_user
        Gitlab::Import::ImportUserCreator.new(portable: namespace).execute
      end

      def placeholder_user_limit_exceeded?
        ::Import::PlaceholderUserLimit.new(namespace: namespace).exceeded?
      end

      def lock_key(source_user_identifier)
        "import:source_user_mapper:#{namespace.id}:#{import_type}:#{source_hostname}:#{source_user_identifier}"
      end
    end
  end
end
