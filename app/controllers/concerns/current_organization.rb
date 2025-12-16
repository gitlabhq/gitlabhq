# frozen_string_literal: true

module CurrentOrganization
  extend ActiveSupport::Concern

  def set_current_organization
    return if ::Current.organization_assigned

    organization = Gitlab::Current::Organization.new(
      params: organization_params,
      user: current_user,
      rack_env: request.env
    ).organization

    ::Current.organization = organization
  end
end
