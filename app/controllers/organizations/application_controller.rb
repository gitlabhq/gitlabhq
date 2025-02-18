# frozen_string_literal: true

module Organizations
  class ApplicationController < ::ApplicationController
    before_action :check_feature_flag!
    before_action :organization

    layout 'organization'

    private

    def organization
      organization_path = params.permit(:organization_path)[:organization_path]
      return unless organization_path

      @organization = Organizations::Organization.find_by_path(organization_path)
    end
    strong_memoize_attr :organization

    def check_feature_flag!
      access_denied! unless Feature.enabled?(:ui_for_organizations, current_user)
    end

    def authorize_create_organization!
      access_denied! unless Feature.enabled?(:allow_organization_creation, current_user)
      access_denied! unless can?(current_user, :create_organization)
    end

    def authorize_read_organization!
      access_denied! unless can?(current_user, :read_organization, organization)
    end

    def authorize_read_organization_user!
      access_denied! unless can?(current_user, :read_organization_user, organization)
    end

    def authorize_admin_organization!
      access_denied! unless can?(current_user, :admin_organization, organization)
    end

    def authorize_create_group!
      access_denied! unless can?(current_user, :create_group, organization)
    end
  end
end
