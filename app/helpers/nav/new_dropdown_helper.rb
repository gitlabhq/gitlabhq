# frozen_string_literal: true

module Nav
  module NewDropdownHelper
    def new_dropdown_view_model(group:, project:)
      return unless current_user

      menu_sections = []

      if group&.persisted?
        menu_sections.push(group_menu_section(group))
      elsif project&.persisted?
        menu_sections.push(project_menu_section(project))
      end

      menu_sections.push(general_menu_section)

      {
        title: _("New..."),
        menu_sections: menu_sections.select { |x| x.fetch(:menu_items).any? }
      }
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
            data: { track_event: 'click_link_new_project_group', track_label: 'plus_menu_dropdown' }
          )
        )
      end

      if can?(current_user, :create_subgroup, group)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_subgroup',
            title: _('New subgroup'),
            href: new_group_path(parent_id: group.id),
            data: { track_event: 'click_link_new_subgroup', track_label: 'plus_menu_dropdown' }
          )
        )
      end

      menu_items.push(create_epic_menu_item(group))

      if Gitlab::Experimentation.active?(:invite_members_new_dropdown) && can?(current_user, :admin_group_member, group)
        menu_items.push(
          invite_members_menu_item(
            href: group_group_members_path(group)
          )
        )
      end

      {
        title: _('This group'),
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
            data: { track_event: 'click_link_new_issue', track_label: 'plus_menu_dropdown', qa_selector: 'new_issue_link' }
          )
        )
      end

      if merge_project
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_mr',
            title: _('New merge request'),
            href: project_new_merge_request_path(merge_project),
            data: { track_event: 'click_link_new_mr', track_label: 'plus_menu_dropdown' }
          )
        )
      end

      if can?(current_user, :create_snippet, project)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'new_snippet',
            title: _('New snippet'),
            href: new_project_snippet_path(project),
            data: { track_event: 'click_link_new_snippet_project', track_label: 'plus_menu_dropdown' }
          )
        )
      end

      if Gitlab::Experimentation.active?(:invite_members_new_dropdown) && can_import_members?
        menu_items.push(
          invite_members_menu_item(
            href: project_project_members_path(project)
          )
        )
      end

      {
        title: _('This project'),
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
            data: { track_event: 'click_link_new_project', track_label: 'plus_menu_dropdown', qa_selector: 'global_new_project_link' }
          )
        )
      end

      if current_user.can_create_group?
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_group',
            title: _('New group'),
            href: new_group_path,
            data: { track_event: 'click_link_new_group', track_label: 'plus_menu_dropdown' }
          )
        )
      end

      if current_user.can?(:create_snippet)
        menu_items.push(
          ::Gitlab::Nav::TopNavMenuItem.build(
            id: 'general_new_snippet',
            title: _('New snippet'),
            href: new_snippet_path,
            data: { track_event: 'click_link_new_snippet_parent', track_label: 'plus_menu_dropdown', qa_selector: 'global_new_snippet_link' }
          )
        )
      end

      {
        title: _('GitLab'),
        menu_items: menu_items
      }
    end

    def invite_members_menu_item(href:)
      ::Gitlab::Nav::TopNavMenuItem.build(
        id: 'invite',
        title: s_('InviteMember|Invite members'),
        emoji: ('shaking_hands' if experiment_enabled?(:invite_members_new_dropdown)),
        href: href,
        data: {
          track_event: 'click_link',
          track_label: tracking_label,
          track_property: experiment_tracking_category_and_group(:invite_members_new_dropdown)
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
