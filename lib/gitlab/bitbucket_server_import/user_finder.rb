# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    # Class that can be used for finding a GitLab user ID based on a BitBucket user

    class UserFinder
      attr_reader :project

      CACHE_KEY = 'bitbucket_server-importer/user-finder/%{project_id}/%{by}/%{value}'
      CACHE_USER_ID_NOT_FOUND = -1

      # project - An instance of `Project`
      def initialize(project)
        @project = project
      end

      def author_id(object)
        uid(object) || project.creator_id
      end

      # Object should behave as a object so we can remove object.is_a?(Hash) check
      # This will be fixed in https://gitlab.com/gitlab-org/gitlab/-/issues/412328
      def uid(object)
        # We want this to only match either username or email depending on the flag state.
        # There should be no fall-through.
        if Feature.enabled?(:bitbucket_server_user_mapping_by_username, type: :ops)
          find_user_id(by: :username, value: object.is_a?(Hash) ? object[:author_username] : object.author_username)
        else
          find_user_id(by: :email, value: object.is_a?(Hash) ? object[:author_email] : object.author_email)
        end
      end

      def find_user_id(by:, value:)
        return unless value

        cache_key = build_cache_key(by, value)
        cached_id = cache.read_integer(cache_key)

        return if cached_id == CACHE_USER_ID_NOT_FOUND
        return cached_id if cached_id

        user = if by == :email
                 User.find_by_any_email(value, confirmed: true)
               else
                 User.find_by_username(value)
               end

        user&.id.tap do |id|
          cache.write(cache_key, id || CACHE_USER_ID_NOT_FOUND)
        end
      end

      private

      def cache
        Cache::Import::Caching
      end

      def build_cache_key(by, value)
        format(CACHE_KEY, project_id: project.id, by: by, value: value)
      end
    end
  end
end
