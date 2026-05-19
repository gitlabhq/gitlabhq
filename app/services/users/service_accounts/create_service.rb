# frozen_string_literal: true

module Users
  module ServiceAccounts
    class CreateService < BaseService
      include Gitlab::Utils::StrongMemoize

      attr_accessor :current_user, :params

      def initialize(current_user, params = {})
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return error(error_messages[:no_permission], :forbidden) unless can_create_service_account?

        return error(error_messages[:no_seats], :forbidden) unless creation_allowed?

        create_user
      end

      private

      def username_and_email_generator
        Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: username_prefix,
          email_domain: User::NOREPLY_EMAIL_DOMAIN
        )
      end
      strong_memoize_attr :username_and_email_generator

      def username_prefix
        User::SERVICE_ACCOUNT_PREFIX
      end

      def can_create_service_account?
        can?(current_user, :admin_service_accounts)
      end

      def create_user
        ::Users::CreateService.new(current_user, default_user_params).execute
      end

      def default_user_params
        {
          name: name,
          email: email,
          username: username,
          user_type: :service_account,
          external: true,
          skip_confirmation: skip_confirmation,
          organization_id: params[:organization_id],
          avatar: params[:avatar].presence,
          composite_identity_enforced: !!params[:composite_identity_enforced],
          private_profile: private_profile,
          skip_ai_prefix_validation: params[:skip_ai_prefix_validation]
        }
      end

      def error_messages
        {
          no_permission: s_('ServiceAccount|User does not have permission to create a service account.'),
          no_seats: s_('ServiceAccount|This namespace either does not have an active subscription that can create ' \
            'service accounts, or the subscription has reached its service account creation limit.')
        }
      end

      def email
        params[:email].presence || username_and_email_generator.email
      end

      def username
        params[:username].presence || username_and_email_generator.username
      end

      def name
        params[:name].presence || 'Service account user'
      end

      def private_profile
        params[:private_profile] || false
      end

      # Skip confirmation only for auto-generated email address.
      # Custom addresses should go through confirmation if
      # enabled for the instance.
      def skip_confirmation
        return true if auto_generated_email_address?

        Gitlab::CurrentSettings.email_confirmation_setting_off?
      end

      def auto_generated_email_address?
        email == username_and_email_generator.email
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end

      # Delegates to Authn::ServiceAccounts, which enforces LIMIT_FOR_FREE
      # in CE and bypasses the limit for paid licenses in EE.
      def creation_allowed?
        ::Authn::ServiceAccounts.creation_allowed_for_sm?
      end
    end
  end
end
