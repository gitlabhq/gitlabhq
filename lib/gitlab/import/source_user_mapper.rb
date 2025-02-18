# frozen_string_literal: true

module Gitlab
  module Import
    class SourceUserMapper
      include Gitlab::ExclusiveLeaseHelpers

      LRU_CACHE_SIZE = 100
      LOCK_TTL = 15.seconds.freeze
      LOCK_SLEEP = 0.3.seconds.freeze
      LOCK_RETRIES = 100

      DuplicatedUserError = Class.new(StandardError)

      def initialize(namespace:, import_type:, source_hostname:)
        @namespace = namespace.root_ancestor
        @import_type = import_type
        @source_hostname = Gitlab::UrlHelpers.normalized_base_url(source_hostname)
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
      def find_source_user(source_user_identifier)
        cache_from_request_store[source_user_identifier] ||= ::Import::SourceUser.uncached do
          source_user = ::Import::SourceUser.find_source_user(
            source_user_identifier: source_user_identifier,
            namespace: namespace,
            source_hostname: source_hostname,
            import_type: import_type
          )

          # If the record has no `#mapped_user_id`, the record would be unusuable for import.
          # It can be in this state if the reassigned_to_user, or placeholder_user were deleted
          # unexpectedly. We intentionally do not have a cascade delete association with
          # users on this record as we do not want to have unmapped contributions be lost.
          # In this situation we reset the record.
          source_user = reset_source_user!(source_user) if reset_source_user?(source_user)

          source_user
        end
      end

      # Finds a source user by the provided `source_user_identifier` or creates a new one
      def find_or_create_source_user(source_name:, source_username:, source_user_identifier:, cache: true)
        source_user = find_source_user(source_user_identifier)
        return source_user if source_user

        source_user = create_source_user(
          source_name: source_name,
          source_username: source_username,
          source_user_identifier: source_user_identifier
        )

        cache_from_request_store[source_user_identifier] = source_user if cache

        source_user
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
        rescue ActiveRecord::RecordInvalid => e
          raise unless e.record.errors.where(:source_user_identifier, :taken).any? # rubocop: disable CodeReuse/ActiveRecord -- not ActiveRecord

          find_source_user(source_user_identifier)
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
        raise DuplicatedUserError.new(e.message), cause: e
      rescue ActiveRecord::RecordInvalid => e
        raise DuplicatedUserError.new(e.message), cause: e if duplicate_user_errors?(e.record)

        raise
      end

      def create_placeholder_user(import_source_user)
        return namespace_import_user if placeholder_user_limit_exceeded? || namespace.user_namespace?

        Gitlab::Import::PlaceholderUserCreator.new(import_source_user).execute
      end

      def namespace_import_user
        Gitlab::Import::ImportUserCreator.new(portable: namespace).execute
      end

      def placeholder_user_limit_exceeded?
        ::Import::PlaceholderUserLimit.new(namespace: namespace).exceeded?
      end

      def reset_source_user?(source_user)
        source_user && source_user.mapped_user_id.nil?
      end

      def reset_source_user!(source_user)
        in_lock(
          lock_key(source_user.source_user_identifier), ttl: LOCK_TTL, sleep_sec: LOCK_SLEEP, retries: LOCK_RETRIES
        ) do |retried|
          if retried
            source_user.reset
            next source_user unless reset_source_user?(source_user)
          end

          ::Import::Framework::Logger.info(
            message: 'Resetting source user state',
            source_user_id: source_user.id,
            source_user_status: source_user.status,
            source_user_reassign_to_user_id: source_user.reassign_to_user_id,
            source_user_placeholder_user_id: source_user.placeholder_user_id
          )

          source_user.status = 0
          source_user.reassignment_token = nil
          source_user.reassign_to_user = nil
          source_user.placeholder_user ||= create_placeholder_user(source_user)

          next source_user if source_user.save

          ::Import::Framework::Logger.error(
            message: 'Failed to save source user after resetting',
            source_user_id: source_user.id,
            source_user_validation_errors: source_user.errors.full_messages
          )

          source_user.destroy
          nil
        end
      end

      def lock_key(source_user_identifier)
        "import:source_user_mapper:#{namespace.id}:#{import_type}:#{source_hostname}:#{source_user_identifier}"
      end

      # Check validation errors on User records (placeholder or import users) for non-uniqueness.
      # rubocop: disable CodeReuse/ActiveRecord -- not ActiveRecord
      def duplicate_user_errors?(record)
        record.errors.where(:email, :taken).any? || record.errors.where(:username, :taken).any?
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
