# frozen_string_literal: true

module Organizations
  class ApplicationController < ::ApplicationController
    skip_before_action :authenticate_user!
    before_action :organization

    layout 'organization'

    private

    def organization
      return unless params[:organization_path]

      @organization = Organizations::Organization.find_by_path(params[:organization_path])
    end
    strong_memoize_attr :organization

    def authorize_action!(action)
      return if Feature.enabled?(:ui_for_organizations, current_user) &&
        can?(current_user, action, organization)

      access_denied!
    end
  end
end
