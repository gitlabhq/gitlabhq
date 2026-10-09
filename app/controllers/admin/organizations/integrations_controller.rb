# frozen_string_literal: true

module Admin
  module Organizations
    class IntegrationsController < Admin::Organizations::ApplicationController
      extend ::Gitlab::Utils::Override

      before_action :authorize_update_integration!
      before_action :set_organization

      include ::Integrations::Actions
      include Admin::IntegrationsActions

      def index
        @integrations = Integration.find_or_initialize_all_non_project_specific(
          Integration.for_organization(::Current.organization), include_instance_specific: true
        ).reject { |integration| instance_only_integration?(integration.to_param) }
          .sort_by { |integration| integration.title.downcase }
      end

      # Integrations::Actions#reset assumes the integration exists, which isn't the case for
      # instance-only integrations.
      override :reset
      def reset
        return render_404 unless integration

        super
      end

      private

      def authorize_update_integration!
        access_denied! unless current_user.can?(:update_integration, ::Current.organization)
      end

      def set_organization
        @organization = ::Current.organization
      end

      def integrations_organization
        ::Current.organization
      end

      # Instance-only integrations (for example Beyond Identity) are still read from the
      # first instance-level row by other code, so they can't be managed per organization yet.
      def instance_only_integration?(name)
        name.in?(Integration.instance_specific_integration_names)
      end

      override :find_or_initialize_non_project_specific_integration
      def find_or_initialize_non_project_specific_integration(name)
        return if instance_only_integration?(name)

        super
      end

      override :integration_edit_path
      def integration_edit_path
        scoped_edit_integration_path(integration, organization: ::Current.organization)
      end
    end
  end
end
