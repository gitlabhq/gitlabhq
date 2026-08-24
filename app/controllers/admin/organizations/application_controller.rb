# frozen_string_literal: true

module Admin
  module Organizations
    class ApplicationController < Admin::ApplicationController
      extend Gitlab::Utils::Override

      layout 'admin/organization'

      skip_before_action :authenticate_admin!, unless: :can_access_instance_admin_area?
      skip_before_action :enforce_step_up_authentication, unless: :can_access_instance_admin_area?

      before_action :authorize_access_organization_admin_area!

      private

      override :authorization_subject
      def authorization_subject
        ::Current.organization
      end

      def authorize_access_organization_admin_area!
        return if org_admin_area_enabled? && current_user&.can?(:access_organization_admin_area, authorization_subject)

        access_denied!
      end

      def org_admin_area_enabled?
        ::Organizations::Release.enabled?(:org_admin_area, authorization_subject)
      end

      def can_access_instance_admin_area?
        current_user&.can_access_admin_area?
      end

      override :set_current_organization
      def set_current_organization
        # Admin area must only set current organization from path - no user:,
        # unlike CurrentOrganization#set_current_organization.
        ::Current.organization_resolver ||= Gitlab::Current::Organization.new(
          params: organization_params,
          rack_env: request.env
        )

        return if ::Current.organization_assigned

        ::Current.organization = ::Current.organization_resolver.organization
      end
    end
  end
end

Admin::Organizations::ApplicationController.prepend_mod_with('Admin::Organizations::ApplicationController')
