# frozen_string_literal: true

module Gitlab
  module Import
    class PlaceholderUserCreator
      def initialize(import_type:, source_hostname:, source_name:, source_username:)
        @import_type = import_type
        @source_hostname = source_hostname
        @source_name = source_name
        @source_username = source_username
      end

      def execute
        user = User.new(
          user_type: :placeholder,
          name: placeholder_name,
          username: placeholder_username,
          email: placeholder_email
        )

        user.assign_personal_namespace(Organizations::Organization.default_organization)
        Namespace.with_disabled_organization_validation do
          user.save!
        end
        user
      end

      private

      attr_reader :import_type, :source_hostname, :source_name, :source_username

      def placeholder_name
        # Some APIs don't expose users' names, so set a default if it's nil
        return "Placeholder #{import_type} Source User" unless source_name

        "Placeholder #{source_name.slice(0, 127)}"
      end

      def placeholder_username
        # Some APIs don't expose users' usernames, so set a default if it's nil
        username_pattern = "#{valid_source_username}_placeholder_user_%s"
        lambda_for_unique_username = ->(username) { User.username_exists?(username) }
        uniquify_string(username_pattern, lambda_for_unique_username)
      end

      def placeholder_email
        email_pattern = "#{valid_source_username}_placeholder_user_%s@#{Settings.gitlab.host}"
        lambda_for_unique_email = ->(email) { User.find_by_email(email) || ::Email.find_by_email(email) }
        uniquify_string(email_pattern, lambda_for_unique_email)
      end

      def valid_source_username
        return fallback_username unless source_username

        sanitized_source_username = source_username.gsub(/[^A-Za-z0-9]/, '')
        return fallback_username if sanitized_source_username.empty?

        sanitized_source_username.slice(0, User::MAX_USERNAME_LENGTH - 55)
      end

      def fallback_username
        "#{import_type}_source_username"
      end

      def uniquify_string(base_pattern, lambda_for_uniqueness)
        uniquify = Gitlab::Utils::Uniquify.new(1)

        uniquify.string(->(unique_number) { format(base_pattern, unique_number) }) do |str|
          lambda_for_uniqueness.call(str)
        end
      end
    end
  end
end
