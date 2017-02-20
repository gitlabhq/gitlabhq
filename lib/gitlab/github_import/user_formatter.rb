module Gitlab
  module GithubImport
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
        users  = ::User.arel_table
        emails = ::Email.arel_table

        left_join_emails = users.join(emails, Arel::Nodes::OuterJoin).on(
          users[:id].eq(emails[:user_id])
        ).join_sources

        User.select(:id)
            .joins(left_join_emails)
            .where(users[:email].eq(email).or(emails[:email].eq(email)))
            .first.try(:id)
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
