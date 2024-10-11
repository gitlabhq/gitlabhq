# frozen_string_literal: true

module Admin
  module UsersHelper
    def show_new_user_organization_field?
      ::Organizations::Organization.exists?
    end

    def new_user_organization_field_app_data
      initial_organization = ::Organizations::Organization.first

      {
        has_multiple_organizations: ::Organizations::Organization.limit(2).count > 1,
        initial_organization: initial_organization.slice(
          :id,
          :name
        ).merge({ avatar_url: initial_organization.avatar_url(size: 96) })
      }.to_json
    end
  end
end
