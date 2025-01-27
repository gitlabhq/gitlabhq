# frozen_string_literal: true

module Organizations
  module OrganizationHelper
    def organization_layout_nav
      return 'organization' unless current_controller?('organizations')

      current_action?(:index, :new) ? "your_work" : "organization"
    end

    def organization_show_app_data(organization)
      {
        organization: organization.slice(:id, :name, :description_html, :visibility)
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
        organization: organization.slice(:id, :name, :path, :description, :visibility_level)
          .merge({ avatar: organization.avatar_url(size: 192) })
      }.merge(shared_new_settings_general_app_data).to_json
    end

    def organization_groups_and_projects_app_data(organization)
      {
        user_preference_sort: current_user&.user_preference&.organization_groups_projects_sort,
        user_preference_display: current_user&.user_preference&.organization_groups_projects_display
      }.merge(shared_groups_and_projects_app_data(organization)).to_json
    end

    def organization_index_app_data
      shared_organization_index_app_data.to_json
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
        default_visibility_level: default_group_visibility
      }.merge(shared_organization_groups_app_data(organization)).to_json
    end

    def organization_groups_edit_app_data(organization, group)
      {
        group: group.slice(:id, :full_name, :name, :visibility_level, :path, :full_path)
      }.merge(shared_organization_groups_app_data(organization)).to_json
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

    def organization_activity_app_data(organization)
      {
        organization_activity_path: activity_organization_path(organization, { format: :json }),
        organization_activity_event_types: organization_activity_event_types,
        organization_activity_all_event: EventFilter::ALL
      }.to_json
    end

    private

    def shared_groups_and_projects_app_data(organization)
      {
        organization_gid: organization.to_global_id,
        new_group_path: new_groups_organization_path(organization),
        groups_path: groups_organization_path(organization),
        new_project_path: new_project_path,
        can_create_group: can?(current_user, :create_group, organization),
        can_create_project: current_user&.can_create_project?,
        organization_groups_projects_sort: current_user&.organization_groups_projects_sort,
        organization_groups_projects_display: current_user&.organization_groups_projects_display,
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
        can_create_organization: Feature.enabled?(:allow_organization_creation, current_user) &&
          can?(current_user, :create_organization)
      }
    end

    def shared_organization_groups_app_data(organization)
      {
        base_path: root_url,
        groups_and_projects_organization_path:
          groups_and_projects_organization_path(organization, { display: 'groups' }),
        groups_organization_path: groups_organization_path(organization),
        available_visibility_levels: available_visibility_levels_for_group(organization),
        restricted_visibility_levels: restricted_visibility_levels,
        path_maxlength: ::Namespace::URL_MAX_LENGTH,
        path_pattern: Gitlab::PathRegex::NAMESPACE_FORMAT_REGEX_JS
      }
    end

    def available_visibility_levels_for_group(organization)
      group = Group.new(organization: organization)
      available_visibility_levels(group)
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

    def organization_activity_event_types
      [
        {
          title: _('Comment'),
          value: EventFilter::COMMENTS
        },
        {
          title: _('Design'),
          value: EventFilter::DESIGNS
        },
        {
          title: _('Issue'),
          value: EventFilter::ISSUE
        },
        {
          title: _('Merge'),
          value: EventFilter::MERGED
        },
        {
          title: _('Repository'),
          value: EventFilter::PUSH
        },
        {
          title: _('Membership'),
          value: EventFilter::TEAM
        },
        {
          title: _('Wiki'),
          value: EventFilter::WIKI
        }
      ]
    end
  end
end

Organizations::OrganizationHelper.prepend_mod_with('Organizations::OrganizationHelper')
