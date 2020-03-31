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

        identities = ::Identity.arel_table

        User.select(:id)
            .joins(:identities)
            .find_by(identities[:provider].eq(:github).and(identities[:extern_uid].eq(id)))
            .try(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
