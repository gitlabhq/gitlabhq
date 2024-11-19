# frozen_string_literal: true

module Nav
  module NewDropdownHelper
    def new_dropdown_view_model(group:, project:)
      return unless current_user

      menu_sections = []
      data = { title: _('Create new...') }

      if project&.persisted?
        menu_sections.push(project_menu_section(project))
      elsif group&.persisted?
        menu_sections.push(group_menu_section(group))
      end

      menu_sections.push(general_menu_section)

      data[:menu_sections] = menu_sections.select { |x| x.fetch(:menu_items).any? }

      data
    end

    private

    def group_menu_section(group)
      menu_items = []

      if can?(current_user, :create_projects, group)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_project',
            title: _('New project/repository'),
            href: new_project_path(namespace_id: group.id),
            data: {
              track_action: 'click_link_new_project_group',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top'
            }
          )
        )
      end

      if can?(current_user, :create_subgroup, group)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_subgroup',
            title: _('New subgroup'),
            href: new_group_path(parent_id: group.id, anchor: 'create-group-pane'),
            data: {
              track_action: 'click_link_new_subgroup',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top'
            }
          )
        )
      end

      menu_items.push(create_epic_menu_item(group))

      if can?(current_user, :admin_group_member, group)
        menu_items.push(invite_members_menu_item(partial: 'groups/invite_members_top_nav_link'))
      end

      {
        title: _('In this group'),
        menu_items: menu_items.compact
      }
    end

    def project_menu_section(project)
      menu_items = []
      merge_project = merge_request_source_project_for_project(project)

      if show_new_issue_link?(project)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_issue',
            title: _('New issue'),
            href: new_project_issue_path(project),
            data: {
              track_action: 'click_link_new_issue',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top',
              testid: 'new_issue_link'
            }
          )
        )
      end

      if merge_project
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_mr',
            title: _('New merge request'),
            href: project_new_merge_request_path(merge_project),
            data: {
              track_action: 'click_link_new_mr',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top'
            }
          )
        )
      end

      if can?(current_user, :create_snippet, project)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_snippet',
            title: _('New snippet'),
            href: new_project_snippet_path(project),
            data: {
              track_action: 'click_link_new_snippet_project',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top'
            }
          )
        )
      end

      if can_admin_project_member?(project)
        menu_items.push(invite_members_menu_item(partial: 'projects/invite_members_top_nav_link'))
      end

      {
        title: _('In this project'),
        menu_items: menu_items
      }
    end

    def general_menu_section
      menu_items = []

      if current_user.can_create_project?
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_project',
            title: _('New project/repository'),
            href: new_project_path,
            data: {
              track_action: 'click_link_new_project',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top',
              testid: 'global-new-project-link'
            }
          )
        )
      end

      if current_user.can_create_group?
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_group',
            title: _('New group'),
            href: new_group_path,
            data: {
              track_action: 'click_link_new_group',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top',
              testid: 'global-new-group-link'
            }
          )
        )
      end

      if Feature.enabled?(:ui_for_organizations, current_user) &&
          Feature.enabled?(:allow_organization_creation, current_user) &&
          current_user.can?(:create_organization)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_organization',
            title: s_('Organization|New organization'),
            href: new_organization_path,
            data: {
              track_action: 'click_link_new_organization_parent',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top',
              testid: 'global_new_organization_link'
            }
          )
        )
      end

      if current_user.can?(:create_snippet)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_snippet',
            title: _('New snippet'),
            href: new_snippet_path,
            data: {
              track_action: 'click_link_new_snippet_parent',
              track_label: 'plus_menu_dropdown',
              track_property: 'navigation_top',
              testid: 'global-new-snippet-link'
            }
          )
        )
      end

      {
        title: _('In GitLab'),
        menu_items: menu_items
      }
    end

    def invite_members_menu_item(partial:)
      ::Gitlab::Nav::TopNavMenuItem.build(
        id: 'invite',
        title: s_('InviteMember|Invite members'),
        icon: 'shaking_hands',
        partial: partial,
        component: 'invite_members',
        data: {
          trigger_source: 'top_nav',
          trigger_element: 'text-emoji'
        }
      )
    end

    # Overridden in EE
    def create_epic_menu_item(group)
      nil
    end
  end
end

Nav::NewDropdownHelper.prepend_mod
