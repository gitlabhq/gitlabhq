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
        return nil unless email

        User.find_by_any_email(email)
            .try(:id)
      end

      def find_by_external_uid
        return nil unless id

        identities = ::Identity.arel_table

        User.select(:id)
            .joins(:identities).where(identities[:provider].eq(:github)
            .and(identities[:extern_uid].eq(id)))
            .first
            .try(:id)
      end
    end
  end
end
