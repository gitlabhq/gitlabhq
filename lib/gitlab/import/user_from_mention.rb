# frozen_string_literal: true

module Gitlab
  module Import
    module UserFromMention
      SOURCE_USER_CACHE_KEY = '%s/project/%s/source/%s'
      SOURCE_USERNAME_CACHE_KEY = '%s/project/%s/source/username/%s'

      USER_MAPPABLE_TYPES = [
        :email
      ].freeze

      def user_from_cache(mention)
        cached_user_value_hash = read(mention)
        cached_user_value_hash ||= read_cached_email(mention)

        return unless cached_user_value_hash

        mapping_type = cached_user_value_hash['type']
        user_value = cached_user_value_hash['value']
        return user_value if USER_MAPPABLE_TYPES.exclude?(mapping_type.to_sym)

        find_user(user_value)
      end

      def cache_multiple(hash)
        ::Gitlab::Cache::Import::Caching.write_multiple(hash, timeout: timeout)
      end

      def source_user_cache_key(importer, project_id, source_key)
        format(SOURCE_USER_CACHE_KEY, importer, project_id, source_key)
      end

      def source_user_cache_value(source_value, type:)
        { value: source_value, type: type }.to_json
      end

      private

      def read(mention)
        Gitlab::Json.parse(
          ::Gitlab::Cache::Import::Caching.read(source_user_cache_key(importer, project_id, mention))
        )
      end

      def find_user(email)
        User.find_by_any_email(email, confirmed: true)
      end

      def timeout
        ::Gitlab::Cache::Import::Caching::LONGER_TIMEOUT
      end

      def read_cached_email(mention)
        # Attempt to find a cached email in case a user email was cached before changes to the cache structure were
        # merged but before the cached email could be read and mapped in the import
        source_username_cache_key = format(SOURCE_USERNAME_CACHE_KEY, importer, project_id, mention)
        cached_email = ::Gitlab::Cache::Import::Caching.read(source_username_cache_key)

        return unless cached_email

        { value: cached_email, type: :email }.with_indifferent_access
      end
    end
  end
end
