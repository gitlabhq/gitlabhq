# frozen_string_literal: true

module Users
  module EmailVerification
    class BaseService
      VALID_ATTRS = %i[unlock_token confirmation_token].freeze

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
    end
  end
end
