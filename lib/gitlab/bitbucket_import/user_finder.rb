# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class UserFinder
      USER_ID_FOR_AUTHOR_CACHE_KEY = 'bitbucket-importer/user-finder/%{project_id}/%{author}'
      CACHE_USER_ID_NOT_FOUND = -1

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def find_user_id(author)
        return unless author

        cache_key = build_cache_key(author)
        cached_id = cache.read_integer(cache_key)

        return if cached_id == CACHE_USER_ID_NOT_FOUND
        return cached_id if cached_id

        id = User.by_provider_and_extern_uid(:bitbucket, author).select(:id).first&.id

        cache.write(cache_key, id || CACHE_USER_ID_NOT_FOUND)

        id
      end

      def gitlab_user_id(project, username)
        find_user_id(username) || project.creator_id
      end

      private

      def cache
        Cache::Import::Caching
      end

      def build_cache_key(author)
        format(USER_ID_FOR_AUTHOR_CACHE_KEY, project_id: project.id, author: author)
      end
    end
  end
end
