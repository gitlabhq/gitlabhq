# frozen_string_literal: true

module Gitlab
  module PrivateCommitEmail
    TOKEN = "_private"

    class << self
      def regex
        Gitlab::SafeRequestStore.fetch(:private_commit_email_regex) do
          hostname_regexp = Regexp.escape(Gitlab::CurrentSettings.current_application_settings.commit_email_hostname)

          /\A(?<id>([0-9]+))\-([^@]+)@#{hostname_regexp}\z/
        end
      end

      def user_id_for_email(email)
        match = email&.match(regex)
        return unless match

        match[:id].to_i
      end

      def user_ids_for_emails(emails)
        emails.filter_map { |email| user_id_for_email(email) }.uniq
      end

      def for_user(user)
        hostname = Gitlab::CurrentSettings.current_application_settings.commit_email_hostname

        "#{user.id}-#{user.username}@#{hostname}"
      end
    end
  end
end
