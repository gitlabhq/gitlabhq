# frozen_string_literal: true

module Gitlab
  module Import
    class PlaceholderUserCreator
      LAMBDA_FOR_UNIQUE_USERNAME = ->(username) { User.username_exists?(username) }.freeze
      LAMBDA_FOR_UNIQUE_EMAIL = ->(email) { User.find_by_email(email) || ::Email.find_by_email(email) }.freeze

      def initialize(import_type:, source_hostname:, source_name:, source_username:, namespace:)
        @import_type = import_type
        @source_hostname = source_hostname
        @source_name = source_name
        @source_username = source_username
        @namespace = namespace
      end

      def execute
        user = User.new(
          user_type: :placeholder,
          name: placeholder_name,
          username: placeholder_username,
          email: placeholder_email
        )

        user.assign_personal_namespace(namespace.organization)
        user.save!

        user
      end

      private

      attr_reader :import_type, :namespace, :source_hostname, :source_name, :source_username

      def placeholder_name
        # Some APIs don't expose users' names, so set a default if it's nil
        return "Placeholder #{import_type} Source User" unless source_name

        "Placeholder #{source_name.slice(0, 127)}"
      end

      def placeholder_username
        # Some APIs don't expose users' usernames, so set a default if it's nil
        username_pattern = "#{valid_username_segment}_placeholder_user_%s"

        uniquify_string(username_pattern, LAMBDA_FOR_UNIQUE_USERNAME)
      end

      def placeholder_email
        email_pattern = "#{valid_username_segment}_placeholder_user_%s@#{Settings.gitlab.host}"

        uniquify_string(email_pattern, LAMBDA_FOR_UNIQUE_EMAIL)
      end

      def valid_username_segment
        return fallback_username_segment unless source_username

        sanitized_source_username = source_username.gsub(/[^A-Za-z0-9]/, '')
        return fallback_username_segment if sanitized_source_username.empty?

        sanitized_source_username.slice(0, User::MAX_USERNAME_LENGTH - 55)
      end

      def fallback_username_segment
        "#{namespace.path}_#{import_type}"
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
