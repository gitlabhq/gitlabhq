# frozen_string_literal: true

module Gitlab
  module PrivateCommitEmail
    TOKEN = "_private".freeze

    class << self
      def regex
        hostname_regexp = Regexp.escape(Gitlab::CurrentSettings.current_application_settings.commit_email_hostname)

        /\A(?<id>([0-9]+))\-([^@]+)@#{hostname_regexp}\z/
      end

      def user_id_for_email(email)
        match = email&.match(regex)
        return unless match

        match[:id].to_i
      end

      def for_user(user)
        hostname = Gitlab::CurrentSettings.current_application_settings.commit_email_hostname

        "#{user.id}-#{user.username}@#{hostname}"
      end
    end
  end
end
