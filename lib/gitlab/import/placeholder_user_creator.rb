# frozen_string_literal: true

module Gitlab
  module Import
    class PlaceholderUserCreator
      delegate :import_type, :namespace, :source_user_identifier, :source_name, :source_username, to: :source_user,
        private: true

      PLACEHOLDER_EMAIL_REGEX = ::Gitlab::UntrustedRegexp.new(
        "_placeholder_[[:alnum:]]+@noreply.#{Settings.gitlab.host}"
      )
      LEGACY_PLACEHOLDER_EMAIL_REGEX = ::Gitlab::UntrustedRegexp.new(
        "(#{::Import::HasImportSource::IMPORT_SOURCES.except(:none).keys.join('|')})" \
          '(_[0-9A-Fa-f]+_[0-9]+' \
          "@#{Settings.gitlab.host})"
      )

      class << self
        def placeholder_email?(email)
          PLACEHOLDER_EMAIL_REGEX.match?(email) || LEGACY_PLACEHOLDER_EMAIL_REGEX.match?(email)
        end
      end

      def initialize(source_user)
        @source_user = source_user
      end

      def execute
        user = User.new(
          user_type: :placeholder,
          name: placeholder_name,
          username: username_and_email_generator.username,
          email: username_and_email_generator.email
        )

        user.skip_confirmation_notification!
        user.assign_personal_namespace(namespace.organization)
        user.save!

        log_placeholder_user_creation(user)

        user
      end

      def placeholder_name
        # Some APIs don't expose users' names, so set a default if it's nil
        return "Placeholder #{import_type} Source User" unless source_name

        "Placeholder #{source_name.slice(0, 127)}"
      end

      private

      attr_reader :source_user

      def username_and_email_generator
        @generator ||= Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: username_prefix,
          email_domain: "noreply.#{Gitlab.config.gitlab.host}",
          random_segment: random_segment
        )
      end

      def username_prefix
        "#{valid_username_segment}_placeholder"
      end

      # Some APIs don't expose users' usernames, so set a fallback if it's nil
      def valid_username_segment
        return import_type unless source_username

        sanitized_source_username = source_username.gsub(/[^A-Za-z0-9]/, '')
        return import_type if sanitized_source_username.empty?

        sanitized_source_username.slice(0, User::MAX_USERNAME_LENGTH - 55)
      end

      def random_segment
        Zlib.crc32([namespace.path, source_user_identifier].join).to_s(36)
      end

      def log_placeholder_user_creation(user)
        ::Import::Framework::Logger.info(
          message: 'Placeholder user created',
          source_user_id: source_user.id,
          import_type: source_user.import_type,
          namespace_id: source_user.namespace_id,
          user_id: user.id
        )
      end
    end
  end
end
