# frozen_string_literal: true

module Admin
  module Organizations
    class ApplicationController < Admin::ApplicationController
      extend Gitlab::Utils::Override

      skip_before_action :authenticate_admin!, unless: :can_access_instance_admin_area?
      skip_before_action :enforce_step_up_authentication, unless: :can_access_instance_admin_area?

      before_action :authorize_access_organization_admin_area!

      private

      def authorize_access_organization_admin_area!
        access_denied! unless current_user&.can?(:access_organization_admin_area, ::Current.organization)
      end

      def can_access_instance_admin_area?
        current_user&.can_access_admin_area?
      end

      override :set_current_organization
      def set_current_organization
        return if ::Current.organization_assigned

        # Admin area must only set current organization from path
        organization = Gitlab::Current::Organization.new(
          params: organization_params,
          rack_env: request.env
        ).organization

        ::Current.organization = organization
      end
    end
  end
end

Admin::Organizations::ApplicationController.prepend_mod_with('Admin::Organizations::ApplicationController')
