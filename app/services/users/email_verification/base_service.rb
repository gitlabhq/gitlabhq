# frozen_string_literal: true

module Users
  module EmailVerification
    class BaseService
      VALID_ATTRS = %i[unlock_token confirmation_token email_otp].freeze

      def initialize(attr:, user:)
        @attr = attr
        @user = user

        validate_attr!
      end

      protected

      attr_reader :attr, :user, :token

      def validate_attr!
        raise ArgumentError, 'Invalid attribute' unless attr.in?(VALID_ATTRS)
      end

      def digest
        Devise.token_generator.digest(User, user.email.downcase.strip, token)
      end

      def attr_value
        # Double check for defense-in-depth
        validate_attr!
        # We use public_send instead of hash access (user[attr]) to
        # support attributes provided via delegation
        user.public_send(attr) # rubocop:disable GitlabSecurity/PublicSend -- argument is checked above
      end
    end
  end
end
