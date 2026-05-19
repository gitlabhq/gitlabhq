# frozen_string_literal: true

module Users
  module ServiceAccounts
    class UpdateService < BaseService
      attr_reader :current_user, :user, :params

      ALLOWED_PARAMS = [:username, :name, :email].freeze

      def initialize(current_user, user, params = {})
        @current_user = current_user
        @user = user
        @params = params.slice(*ALLOWED_PARAMS).compact_blank
      end

      def execute
        return error(error_messages[:not_service_account], :bad_request) unless user.service_account?
        return error(error_messages[:no_permission], :forbidden) unless can_update_service_account?

        update_result = update_user

        if update_result[:status] == :success
          success
        else
          error(update_result[:message], :bad_request)
        end
      end

      private

      def can_update_service_account?
        can?(current_user, :admin_service_accounts)
      end

      def email_changed?
        params[:email].present? && params[:email] != user.email
      end

      def skip_confirmation?
        return unless ValidateEmail.valid?(params[:email])

        Gitlab::CurrentSettings.email_confirmation_setting_off?
      end

      def update_params
        params.merge(user: user)
      end

      def update_user
        user.skip_reconfirmation! if email_changed? && skip_confirmation?
        Users::UpdateService.new(current_user, update_params).execute
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end

      def success
        ServiceResponse.success(message: _('Service account was successfully updated.'), payload: { user: user })
      end

      def error_messages
        {
          no_permission: s_('ServiceAccount|User does not have permission to update a service account.'),
          not_service_account: s_('ServiceAccount|User is not a service account')
        }
      end
    end
  end
end

Users::ServiceAccounts::UpdateService.prepend_mod
