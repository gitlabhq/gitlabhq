# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class BaseDeleteService < BaseService
      attr_accessor :current_user, :user

      def initialize(current_user, user)
        @current_user = current_user
        @user = user
      end

      def execute(options = {})
        return error(error_messages[:no_permission], :forbidden) unless can_delete_service_account?

        delete_user(options)

        return error(user.errors.full_messages.to_sentence, :bad_request) if user.errors.present?

        success
      end

      private

      def can_delete_service_account?
        return false unless user_provisioned_resource

        can?(current_user, :delete_service_account, user_provisioned_resource)
      end

      def user_provisioned_resource
        raise Gitlab::AbstractMethodError
      end

      def delete_user(options)
        options[:skip_authorization] = true

        # Can't access current_user method from run_after_commit_or_now
        current_user_var = current_user

        user.run_after_commit_or_now do
          delete_async(deleted_by: current_user_var, params: options)
        end
      end

      def error_messages
        {
          no_permission: s_('ServiceAccount|User does not have permission to delete a service account.')
        }
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end

      def success
        ServiceResponse.success(message: "User successfully deleted")
      end
    end
  end
end
