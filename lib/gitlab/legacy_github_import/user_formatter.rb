# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class UserFormatter
      attr_reader :client, :raw

      GITEA_GHOST_EMAIL = 'ghost_user@gitea_import_dummy_email.com'

      def initialize(client, raw)
        @client = client
        @raw = raw
      end

      def id
        raw[:id]
      end

      def login
        raw[:login]
      end

      def gitlab_id
        return @gitlab_id if defined?(@gitlab_id)

        @gitlab_id = find_by_external_uid || find_by_email
      end

      private

      def email
        # Gitea marks deleted users as 'Ghost' users and removes them from
        # their system. So for Gitea 'Ghost' users  we need to assign a dummy
        # email address to avoid querying the Gitea api for a non existing user
        if raw[:login] == 'Ghost' && raw[:id] == -1
          @email = GITEA_GHOST_EMAIL
        else
          @email ||= client.user(raw[:login]).to_h[:email]
        end
      end

      def find_by_email
        return unless email

        User.find_by_any_email(email)
            .try(:id)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def find_by_external_uid
        return unless id

        User.by_provider_and_extern_uid(:github, id).select(:id).first&.id
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
