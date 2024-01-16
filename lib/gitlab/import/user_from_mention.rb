# frozen_string_literal: true

module Gitlab
  module Import
    module UserFromMention
      SOURCE_USER_CACHE_KEY = '%s/project/%s/source/username/%s'

      def user_from_cache(mention)
        cached_email = read(mention)

        return unless cached_email

        find_user(cached_email)
      end

      def cache_multiple(hash)
        ::Gitlab::Cache::Import::Caching.write_multiple(hash, timeout: timeout)
      end

      def source_user_cache_key(importer, project_id, username)
        format(SOURCE_USER_CACHE_KEY, importer, project_id, username)
      end

      private

      def read(mention)
        ::Gitlab::Cache::Import::Caching.read(source_user_cache_key(importer, project_id, mention))
      end

      def find_user(email)
        User.find_by_any_email(email, confirmed: true)
      end

      def timeout
        ::Gitlab::Cache::Import::Caching::LONGER_TIMEOUT
      end
    end
  end
end
