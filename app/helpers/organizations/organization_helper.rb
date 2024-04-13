# frozen_string_literal: true

module Organizations
  module OrganizationHelper
    def organization_layout_nav
      return 'organization' unless current_controller?('organizations')

      current_action?(:index, :new) ? "your_work" : "organization"
    end

    def organization_show_app_data(organization)
      {
        organization: organization.slice(:id, :name, :description_html)
          .merge({ avatar_url: organization.avatar_url(size: 128) }),
        groups_and_projects_organization_path: groups_and_projects_organization_path(organization),
        users_organization_path: users_organization_path(organization),
        association_counts: association_counts(organization)
      }.merge(shared_groups_and_projects_app_data(organization)).to_json
    end

    def organization_new_app_data
      shared_new_settings_general_app_data.to_json
    end

    def organization_settings_general_app_data(organization)
      {
        organization: organization.slice(:id, :name, :path, :description)
          .merge({ avatar: organization.avatar_url(size: 192) })
      }.merge(shared_new_settings_general_app_data).to_json
    end

    def organization_groups_and_projects_app_data(organization)
      shared_groups_and_projects_app_data(organization).to_json
    end

    def organization_index_app_data
      shared_organization_index_app_data
    end

    def organization_user_app_data(organization)
      {
        organization_gid: organization.to_global_id,
        paths: organizations_users_paths
      }.to_json
    end

    def home_organization_setting_app_data
      {
        initial_selection: current_user.home_organization_id
      }.to_json
    end

    def organization_groups_new_app_data(organization)
      {
        organization_id: organization.id,
        base_path: root_url,
        groups_organization_path: groups_and_projects_organization_path(organization, { display: 'groups' }),
        mattermost_enabled: Gitlab.config.mattermost.enabled,
        available_visibility_levels: available_visibility_levels(Group),
        restricted_visibility_levels: restricted_visibility_levels,
        default_visibility_level: default_group_visibility,
        path_maxlength: ::Namespace::URL_MAX_LENGTH,
        path_pattern: Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX_JS
      }.to_json
    end

    def admin_organizations_index_app_data
      shared_organization_index_app_data.to_json
    end

    def organization_projects_edit_app_data(organization, project)
      {
        projects_organization_path: groups_and_projects_organization_path(organization, { display: 'projects' }),
        preview_markdown_path: preview_markdown_organizations_path,
        project: project.slice(:id, :name, :full_name, :description)
      }.to_json
    end

    private

    def shared_groups_and_projects_app_data(organization)
      {
        organization_gid: organization.to_global_id,
        projects_empty_state_svg_path: image_path('illustrations/empty-state/empty-projects-md.svg'),
        groups_empty_state_svg_path: image_path('illustrations/empty-state/empty-groups-md.svg'),
        new_group_path: new_groups_organization_path(organization),
        new_project_path: new_project_path,
        can_create_group: can?(current_user, :create_group, organization),
        can_create_project: current_user&.can_create_project?,
        has_groups: has_groups?(organization)
      }
    end

    def shared_new_settings_general_app_data
      {
        preview_markdown_path: preview_markdown_organizations_path,
        organizations_path: organizations_path,
        root_url: root_url
      }
    end

    def shared_organization_index_app_data
      {
        new_organization_url: new_organization_path,
        organizations_empty_state_svg_path: image_path('illustrations/empty-state/empty-organizations-md.svg')
      }
    end

    # See UsersHelper#admin_users_paths for inspiration to this method
    def organizations_users_paths
      {
        admin_user: admin_user_path(:id)
      }
    end

    def has_groups?(organization)
      organization.groups.exists?
    end

    def association_counts(organization)
      Organizations::OrganizationAssociationCounter.new(organization: organization, current_user: current_user).execute
    end
  end
end
