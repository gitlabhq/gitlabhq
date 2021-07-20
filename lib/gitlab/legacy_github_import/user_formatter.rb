# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class UserFormatter
      attr_reader :client, :raw

      delegate :id, :login, to: :raw, allow_nil: true

      def initialize(client, raw)
        @client = client
        @raw = raw
      end

      def gitlab_id
        return @gitlab_id if defined?(@gitlab_id)

        @gitlab_id = find_by_external_uid || find_by_email
      end

      private

      def email
        @email ||= client.user(raw.login).try(:email)
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
