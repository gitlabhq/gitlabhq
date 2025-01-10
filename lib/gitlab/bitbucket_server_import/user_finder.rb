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
        # We want this to only match either placeholder or email
        # depending on the flag state. There should be no fall-through.
        if user_mapping_enabled?(project)
          return unless object[:username]

          source_user_for_author(object).mapped_user_id
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

        user = User.find_by_any_email(value, confirmed: true)

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

      def user_mapping_enabled?(project)
        !!project.import_data.user_mapping_enabled?
      end

      def source_user_for_author(user_data)
        source_user_mapper.find_or_create_source_user(
          source_user_identifier: user_data[:username],
          source_name: user_data[:display_name],
          source_username: user_data[:username]
        )
      end

      def source_user_mapper
        @source_user_mapper ||= Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          import_type: ::Import::SOURCE_BITBUCKET_SERVER,
          source_hostname: project.import_url
        )
      end
    end
  end
end
