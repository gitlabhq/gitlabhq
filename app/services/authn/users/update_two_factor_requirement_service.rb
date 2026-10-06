# frozen_string_literal: true

module Authn
  module Users
    class UpdateTwoFactorRequirementService
      include ::Gitlab::Loggable

      def initialize(user)
        @user = user
      end

      def execute
        # No-op on frozen records: production records are never frozen,
        # so this only guards frozen shared test fixtures from a lazy write.
        return ServiceResponse.error(message: 'User is frozen', payload: { user: user }) if user.frozen?

        periods = requirement_periods

        user.require_two_factor_authentication_from_group = periods.any?
        user.two_factor_grace_period = periods.min || ::User.column_defaults['two_factor_grace_period']

        if user.save
          ServiceResponse.success(payload: { user: user })
        else
          ::Gitlab::AppLogger.warn(
            build_structured_payload_labkit(
              message: 'Failed to save user 2FA requirement',
              ::Labkit::Fields::ERROR_MESSAGE => user.errors.full_messages.to_sentence,
              ::Labkit::Fields::GL_USER_ID => user.id
            )
          )

          ServiceResponse.error(message: user.errors.full_messages, payload: { user: user })
        end
      end

      private

      attr_reader :user

      def requirement_periods
        TwoFactorGroupsFinder.new(user).execute.pluck(:two_factor_grace_period) # rubocop:disable CodeReuse/ActiveRecord, Database/AvoidUsingPluckWithoutLimit -- one value per expanded group, same as the former User#update_two_factor_requirement
      end
    end
  end
end
