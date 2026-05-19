# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class BaseCreateService < ::Users::ServiceAccounts::CreateService
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize

      attr_reader :uniquify_provided_username

      def initialize(current_user, params = {}, uniquify_provided_username: false)
        super(current_user, params)

        @uniquify_provided_username = uniquify_provided_username
      end

      private

      override :create_user
      def create_user
        ::Users::AuthorizedCreateService.new(current_user, default_user_params).execute
      end

      def resource
        raise Gitlab::AbstractMethodError
      end

      def resource_type
        raise Gitlab::AbstractMethodError
      end

      def provisioning_params
        raise Gitlab::AbstractMethodError
      end

      def root_namespace
        resource&.root_ancestor
      end
      strong_memoize_attr :root_namespace

      def username_prefix
        "#{User::SERVICE_ACCOUNT_PREFIX}_#{resource_type}_#{resource.id}"
      end

      override :username
      def username
        if uniquify_provided_username && username_unavailable?(params[:username])
          return uniquify_username(params[:username] || username_prefix)
        end

        super
      end

      def uniquify_username(prefix)
        Gitlab::Utils::UsernameAndEmailGenerator.new(
          username_prefix: prefix,
          random_segment: SecureRandom.hex(3)
        ).username
      end

      override :default_user_params
      def default_user_params
        super.merge(provisioning_params)
      end

      override :error_messages
      def error_messages
        super.merge(
          no_permission:
            format(
              s_('ServiceAccount|User does not have permission to create a service account in this %{resource_type}.'),
              resource_type: resource_type)
        )
      end

      override :can_create_service_account?
      def can_create_service_account?
        return false unless resource
        return true if skip_owner_check?

        can?(current_user, :create_service_account, resource)
      end

      def skip_owner_check?
        false
      end

      def username_unavailable?(username)
        ::Namespace.by_path(username).present? || ::User.username_exists?(username)
      end
    end
  end
end

Namespaces::ServiceAccounts::BaseCreateService.prepend_mod
