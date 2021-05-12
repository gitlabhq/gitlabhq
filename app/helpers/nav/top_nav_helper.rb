# frozen_string_literal: true

module Nav
  module TopNavHelper
    PROJECTS_VIEW = :projects
    GROUPS_VIEW = :groups

    def top_nav_view_model(project:, group:)
      builder = ::Gitlab::Nav::TopNavViewModelBuilder.new

      if current_user
        build_view_model(builder: builder, project: project, group: group)
      else
        build_anonymous_view_model(builder: builder)
      end

      builder.build
    end

    private

    def build_anonymous_view_model(builder:)
      # These come from `app/views/layouts/nav/_explore.html.ham`
      if explore_nav_link?(:projects)
        builder.add_primary_menu_item(
          **projects_menu_item_attrs.merge(
            {
              active: active_nav_link?(path: %w[dashboard#show root#show projects#trending projects#starred projects#index]),
              href: explore_root_path
            })
        )
      end

      if explore_nav_link?(:groups)
        builder.add_primary_menu_item(
          **groups_menu_item_attrs.merge(
            {
              active: active_nav_link?(controller: [:groups, 'groups/milestones', 'groups/group_members']),
              href: explore_groups_path
            })
        )
      end

      if explore_nav_link?(:snippets)
        builder.add_primary_menu_item(
          **snippets_menu_item_attrs.merge(
            {
              active: active_nav_link?(controller: :snippets),
              href: explore_snippets_path
            })
        )
      end
    end

    def build_view_model(builder:, project:, group:)
      # These come from `app/views/layouts/nav/_dashboard.html.haml`
      if dashboard_nav_link?(:projects)
        current_item = project ? current_project(project: project) : {}

        builder.add_primary_menu_item(
          **projects_menu_item_attrs.merge({
            active: active_nav_link?(path: %w[root#index projects#trending projects#starred dashboard/projects#index]),
            css_class: 'qa-projects-dropdown',
            data: { track_label: "projects_dropdown", track_event: "click_dropdown", track_experiment: "new_repo" },
            view: PROJECTS_VIEW
          })
        )
        builder.add_view(PROJECTS_VIEW, container_view_props(namespace: 'projects', current_item: current_item, submenu: projects_submenu))
      end

      if dashboard_nav_link?(:groups)
        current_item = group ? current_group(group: group) : {}

        builder.add_primary_menu_item(
          **groups_menu_item_attrs.merge({
            active: active_nav_link?(path: %w[dashboard/groups explore/groups]),
            css_class: 'qa-groups-dropdown',
            data: { track_label: "groups_dropdown", track_event: "click_dropdown" },
            view: GROUPS_VIEW
          })
        )
        builder.add_view(GROUPS_VIEW, container_view_props(namespace: 'groups', current_item: current_item, submenu: groups_submenu))
      end

      if dashboard_nav_link?(:milestones)
        builder.add_primary_menu_item(
          id: 'milestones',
          title: 'Milestones',
          active: active_nav_link?(controller: 'dashboard/milestones'),
          icon: 'clock',
          data: { qa_selector: 'milestones_link' },
          href: dashboard_milestones_path
        )
      end

      if dashboard_nav_link?(:snippets)
        builder.add_primary_menu_item(
          **snippets_menu_item_attrs.merge({
            active: active_nav_link?(controller: 'dashboard/snippets'),
            data: { qa_selector: 'snippets_link' },
            href: dashboard_snippets_path
          })
        )
      end

      if dashboard_nav_link?(:activity)
        builder.add_primary_menu_item(
          id: 'activity',
          title: 'Activity',
          active: active_nav_link?(path: 'dashboard#activity'),
          icon: 'history',
          data: { qa_selector: 'activity_link' },
          href: activity_dashboard_path
        )
      end

      # Using admin? is generally discouraged because it does not check for
      # "admin_mode". In this case we are migrating code and check both, so
      # we should be good.
      # rubocop: disable Cop/UserAdmin
      if current_user&.admin?
        builder.add_secondary_menu_item(
          id: 'admin',
          title: _('Admin'),
          active: active_nav_link?(controller: 'admin/dashboard'),
          icon: 'admin',
          css_class: 'qa-admin-area-link',
          href: admin_root_path
        )
      end

      if Gitlab::CurrentSettings.admin_mode
        if header_link?(:admin_mode)
          builder.add_secondary_menu_item(
            id: 'leave_admin_mode',
            title: _('Leave Admin Mode'),
            active: active_nav_link?(controller: 'admin/sessions'),
            icon: 'lock-open',
            href: destroy_admin_session_path,
            method: :post
          )
        elsif current_user.admin?
          builder.add_secondary_menu_item(
            id: 'enter_admin_mode',
            title: _('Enter Admin Mode'),
            active: active_nav_link?(controller: 'admin/sessions'),
            icon: 'lock',
            href: new_admin_session_path
          )
        end
      end
      # rubocop: enable Cop/UserAdmin

      if Gitlab::Sherlock.enabled?
        builder.add_secondary_menu_item(
          id: 'sherlock',
          title: _('Sherlock Transactions'),
          icon: 'admin',
          href: sherlock_transactions_path
        )
      end
    end

    def projects_menu_item_attrs
      {
        id: 'project',
        title: _('Projects'),
        icon: 'project'
      }
    end

    def groups_menu_item_attrs
      {
        id: 'groups',
        title: 'Groups',
        icon: 'group'
      }
    end

    def snippets_menu_item_attrs
      {
        id: 'snippets',
        title: _('Snippets'),
        icon: 'snippet'
      }
    end

    def container_view_props(namespace:, current_item:, submenu:)
      {
        namespace: namespace,
        currentUserName: current_user&.username,
        currentItem: current_item,
        linksPrimary: submenu[:primary],
        linksSecondary: submenu[:secondary]
      }
    end

    def current_project(project:)
      return {} unless project.persisted?

      {
        id: project.id,
        name: project.name,
        namespace: project.full_name,
        webUrl: project_path(project),
        avatarUrl: project.avatar_url
      }
    end

    def current_group(group:)
      return {} unless group.persisted?

      {
        id: group.id,
        name: group.name,
        namespace: group.full_name,
        webUrl: group_path(group),
        avatarUrl: group.avatar_url
      }
    end

    def projects_submenu
      # These project links come from `app/views/layouts/nav/projects_dropdown/_show.html.haml`
      builder = ::Gitlab::Nav::TopNavMenuBuilder.new
      builder.add_primary_menu_item(id: 'your', title: _('Your projects'), href: dashboard_projects_path)
      builder.add_primary_menu_item(id: 'starred', title: _('Starred projects'), href: starred_dashboard_projects_path)
      builder.add_primary_menu_item(id: 'explore', title: _('Explore projects'), href: explore_root_path)
      builder.add_secondary_menu_item(id: 'create', title: _('Create new project'), href: new_project_path)
      builder.build
    end

    def groups_submenu
      # These group links come from `app/views/layouts/nav/groups_dropdown/_show.html.haml`
      builder = ::Gitlab::Nav::TopNavMenuBuilder.new
      builder.add_primary_menu_item(id: 'your', title: _('Your groups'), href: dashboard_groups_path)
      builder.add_primary_menu_item(id: 'explore', title: _('Explore groups'), href: explore_groups_path)
      builder.add_secondary_menu_item(id: 'create', title: _('Create group'), href: new_group_path(anchor: 'create-group-pane'))
      builder.build
    end
  end
end

Nav::TopNavHelper.prepend_mod
