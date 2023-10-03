# frozen_string_literal: true

module Organizations
  module OrganizationHelper
    def organization_show_app_data(organization)
      {
        organization: organization.slice(:id, :name),
        groups_and_projects_organization_path: groups_and_projects_organization_path(organization),
        # TODO: Update counts to use real data
        # https://gitlab.com/gitlab-org/gitlab/-/issues/424531
        association_counts: {
          groups: 10,
          projects: 5,
          users: 1050
        }
      }.merge(shared_groups_and_projects_app_data).to_json
    end

    def organization_groups_and_projects_app_data
      shared_groups_and_projects_app_data.to_json
    end

    def organization_index_app_data
      {
        new_organization_url: new_organization_path,
        organizations_empty_state_svg_path: image_path('illustrations/empty-state/empty-organizations-md.svg')
      }
    end

    private

    def shared_groups_and_projects_app_data
      {
        projects_empty_state_svg_path: image_path('illustrations/empty-state/empty-projects-md.svg'),
        groups_empty_state_svg_path: image_path('illustrations/empty-state/empty-groups-md.svg'),
        new_group_path: new_group_path,
        new_project_path: new_project_path
      }
    end
  end
end
