# frozen_string_literal: true

module Users
  class ResetIncomingEmailTokenService < BaseService
    def initialize(current_user:, user:)
      @current_user = current_user
      @user = user
    end

    def execute!
      return ServiceResponse.error(message: s_('Not permitted to reset user feed token')) unless reset_permitted?

      Users::UpdateService.new(current_user, user: user).execute!(&:reset_incoming_email_token!)

      ServiceResponse.success(message: 'Incoming mail token was successfully reset')
    end

    private

    attr_reader :user

    def reset_permitted?
      Ability.allowed?(current_user, :update_user, user)
    end
  end
end
