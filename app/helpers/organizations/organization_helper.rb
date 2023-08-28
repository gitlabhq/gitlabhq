# frozen_string_literal: true

module Organizations
  module OrganizationHelper
    def organization_show_app_data(organization)
      {
        organization: organization.slice(:id, :name),
        groups_and_projects_organization_path: groups_and_projects_organization_path(organization)
      }.to_json
    end
  end
end
