# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class UserFormatter
      include Gitlab::Utils::StrongMemoize

      attr_reader :client, :raw, :project, :source_user_mapper

      GITEA_GHOST_EMAIL = 'ghost_user@gitea_import_dummy_email.com'

      def initialize(client, raw, project, source_user_mapper)
        @client = client
        @raw = raw
        @project = project
        @source_user_mapper = source_user_mapper
      end

      def id
        raw[:id]
      end

      def login
        raw[:login]
      end

      def gitlab_id
        user_mapping_enabled? ? gitlab_user&.id : find_by_email
      end
      strong_memoize_attr :gitlab_id

      def source_user
        return if !user_mapping_enabled? || ghost_user?

        source_user_mapper.find_or_create_source_user(
          source_name: gitea_user[:full_name].presence || gitea_user[:login],
          source_username: gitea_user[:login],
          source_user_identifier: raw[:id]
        )
      end
      strong_memoize_attr :source_user

      private

      def ghost_user?
        raw[:login] == 'Ghost' && raw[:id] == -1
      end

      def gitea_user
        # Gitea marks deleted users as 'Ghost' users and removes them from
        # their system. So for Gitea 'Ghost' users  we need to assign a dummy
        # email address to avoid querying the Gitea api for a non existing user
        user_hash = {}

        if ghost_user?
          user_hash[:login] = user_hash[:full_name] = raw[:login]
          user_hash[:email] = GITEA_GHOST_EMAIL
        else
          user_hash = client.user(raw[:login]).to_h.slice(:id, :login, :full_name, :email)
        end

        user_hash
      end
      strong_memoize_attr :gitea_user

      def find_by_email
        email = gitea_user[:email]

        return unless email

        User.find_by_any_email(email)
            .try(:id)
      end

      def gitlab_user
        return if ghost_user?

        source_user.mapped_user
      end
      strong_memoize_attr :gitlab_user

      def user_mapping_enabled?
        project.import_data.reset.user_mapping_enabled?
      end
      strong_memoize_attr :user_mapping_enabled?
    end
  end
end
