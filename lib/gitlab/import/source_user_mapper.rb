# frozen_string_literal: true

module Gitlab
  module Import
    class SourceUserMapper
      include Gitlab::ExclusiveLeaseHelpers

      LRU_CACHE_SIZE = 8000
      LOCK_TTL = 15.seconds.freeze
      LOCK_SLEEP = 0.3.seconds.freeze
      LOCK_RETRIES = 100

      DuplicatedSourceUserError = Class.new(StandardError)

      def initialize(namespace:, import_type:, source_hostname:)
        @namespace = namespace.root_ancestor
        @import_type = import_type
        @source_hostname = source_hostname
      end

      # Finds a source user by the provided `source_user_identifier`.
      #
      # This method first checks an in-memory LRU (Least Recently Used) cache,
      # stored in `SafeRequestStore`, to avoid unnecessary database queries.
      # If the source user is not present in the cache, it will query the database
      # and store the result in the cache for future use.
      #
      # Since jobs may create source users concurrently, the ActiveRecord query
      # cache is explicitly disabled when querying the database to ensure that
      # we always get the latest data.
      #
      # @param [String] source_user_identifier The identifier for the source user to find.
      # @return [Import::SourceUser, nil] The found source user object, or `nil` if no match is found.
      #
      def find_source_user(source_user_identifier)
        cache_from_request_store[source_user_identifier] ||= ::Import::SourceUser.uncached do
          ::Import::SourceUser.find_source_user(
            source_user_identifier: source_user_identifier,
            namespace: namespace,
            source_hostname: source_hostname,
            import_type: import_type
          )
        end
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
        in_lock(
          lock_key(source_user_identifier), ttl: LOCK_TTL, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRIES
        ) do |retried|
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

          import_source_user.placeholder_user = create_placeholder_user(import_source_user)
          import_source_user.save!
          import_source_user
        end
      rescue PG::UniqueViolation, ActiveRecord::RecordNotUnique => e
        raise DuplicatedSourceUserError.new(e.message), cause: e
      rescue ActiveRecord::RecordInvalid => e
        raise DuplicatedSourceUserError.new(e.message), cause: e if user_has_duplicated_errors?(e.record)

        raise
      end

      def create_placeholder_user(import_source_user)
        return namespace_import_user if placeholder_user_limit_exceeded?

        Gitlab::Import::PlaceholderUserCreator.new(import_source_user).execute
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

      def user_has_duplicated_errors?(record)
        attributes = %i[email username]
        record.errors.filter { |error| error.type == :taken && attributes.include?(error.attribute) }.any?
      end
    end
  end
end
