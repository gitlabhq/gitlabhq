# frozen_string_literal: true

module Organizations
  class ApplicationController < ::ApplicationController
    before_action :organization

    layout 'organization'

    private

    def organization
      return unless params[:organization_path]

      @organization = Organizations::Organization.find_by_path(params[:organization_path])
    end
    strong_memoize_attr :organization

    def authorize_action!(action)
      access_denied! if Feature.disabled?(:ui_for_organizations, current_user)
      access_denied! unless can?(current_user, action, organization)
    end
  end
end
