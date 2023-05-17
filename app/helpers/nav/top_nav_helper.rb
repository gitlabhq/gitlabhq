# frozen_string_literal: true

module Nav
  module TopNavHelper
    PROJECTS_VIEW = :projects
    GROUPS_VIEW = :groups
    NEW_VIEW = :new
    SEARCH_VIEW = :search

    def top_nav_view_model(project:, group:)
      builder = ::Gitlab::Nav::TopNavViewModelBuilder.new

      build_base_view_model(builder: builder, project: project, group: group)

      builder.build
    end

    def top_nav_responsive_view_model(project:, group:)
      builder = ::Gitlab::Nav::TopNavViewModelBuilder.new

      build_base_view_model(builder: builder, project: project, group: group)

      new_view_model = new_dropdown_view_model(project: project, group: group)

      if new_view_model && new_view_model.fetch(:menu_sections)&.any?
        builder.add_view(NEW_VIEW, new_view_model)
      end

      if top_nav_show_search
        builder.add_view(SEARCH_VIEW, ::Gitlab::Nav::TopNavMenuItem.build(**top_nav_search_menu_item_attrs))
      end

      builder.build
    end

    def top_nav_show_search
      header_link?(:search)
    end

    def top_nav_search_menu_item_attrs
      {
        id: 'search',
        title: _('Search'),
        icon: 'search',
        href: search_context.search_url
      }
    end

    private

    def top_nav_localized_headers
      {
        explore: s_('TopNav|Explore'),
        switch_to: s_('TopNav|Switch to')
      }.freeze
    end

    def build_base_view_model(builder:, project:, group:)
      if current_user
        build_view_model(builder: builder, project: project, group: group)
      else
        build_anonymous_view_model(builder: builder)
      end
    end

    def build_anonymous_view_model(builder:)
      if explore_nav_link?(:projects)
        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:explore],
          href: explore_root_path,
          active: nav == 'project' || active_nav_link?(path: %w[dashboard#show root#show projects#trending projects#starred projects#index]),
          **projects_menu_item_attrs
        )
      end

      if explore_nav_link?(:groups)
        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:explore],
          href: explore_groups_path,
          active: nav == 'group' || active_nav_link?(controller: [:groups, 'groups/milestones', 'groups/group_members']),
          **groups_menu_item_attrs
        )
      end

      if explore_nav_link?(:topics)
        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:explore],
          active: active_nav_link?(page: topics_explore_projects_path, path: 'projects#topic'),
          href: topics_explore_projects_path,
          **topics_menu_item_attrs
        )
      end

      if explore_nav_link?(:snippets)
        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:explore],
          active: active_nav_link?(controller: :snippets),
          href: explore_snippets_path,
          **snippets_menu_item_attrs
        )
      end
    end

    def build_view_model(builder:, project:, group:)
      # These come from `app/views/layouts/nav/_dashboard.html.haml`
      if dashboard_nav_link?(:projects)
        current_item = project ? current_project(project: project) : {}

        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:switch_to],
          active: nav == 'project' || active_nav_link?(path: %w[root#index projects#trending projects#starred dashboard/projects#index]),
          data: { track_label: "projects_dropdown", track_action: "click_dropdown", track_property: "navigation_top", qa_selector: "projects_dropdown" },
          view: PROJECTS_VIEW,
          shortcut_href: dashboard_projects_path,
          **projects_menu_item_attrs
        )
        builder.add_view(PROJECTS_VIEW, container_view_props(namespace: 'projects', current_item: current_item, submenu: projects_submenu))
      end

      if dashboard_nav_link?(:groups)
        current_item = group ? current_group(group: group) : {}

        builder.add_primary_menu_item_with_shortcut(
          header: top_nav_localized_headers[:switch_to],
          active: nav == 'group' || active_nav_link?(path: %w[dashboard/groups explore/groups]),
          data: { track_label: "groups_dropdown", track_action: "click_dropdown", track_property: "navigation_top", qa_selector: "groups_dropdown" },
          view: GROUPS_VIEW,
          shortcut_href: dashboard_groups_path,
          **groups_menu_item_attrs
        )
        builder.add_view(GROUPS_VIEW, container_view_props(namespace: 'groups', current_item: current_item, submenu: groups_submenu))
      end

      if dashboard_nav_link?(:your_work)
        builder.add_primary_menu_item(
          id: 'your-work',
          header: top_nav_localized_headers[:switch_to],
          title: _('Your work'),
          href: dashboard_projects_path,
          active: active_nav_link?(controller: []),
          icon: 'work',
          data: { **menu_data_tracking_attrs('your-work') }
        )
      end

      if dashboard_nav_link?(:explore)
        builder.add_primary_menu_item(
          id: 'explore',
          header: top_nav_localized_headers[:switch_to],
          title: _('Explore'),
          href: explore_projects_path,
          active: active_nav_link?(controller: ["explore/groups", "explore/snippets"], page: ["/explore/projects", "/explore", "/explore/projects/topics"], path: ["projects#topic"]),
          icon: 'compass',
          data: { **menu_data_tracking_attrs('explore') }
        )
      end

      if dashboard_nav_link?(:milestones)
        builder.add_shortcut(
          id: 'milestones-shortcut',
          title: _('Milestones'),
          href: dashboard_milestones_path,
          css_class: 'dashboard-shortcuts-milestones'
        )
      end

      if dashboard_nav_link?(:snippets)
        builder.add_shortcut(
          id: 'snippets-shortcut',
          title: _('Snippets'),
          href: dashboard_snippets_path,
          css_class: 'dashboard-shortcuts-snippets'
        )
      end

      if dashboard_nav_link?(:activity)
        builder.add_shortcut(
          id: 'activity-shortcut',
          title: _('Activity'),
          href: activity_dashboard_path,
          css_class: 'dashboard-shortcuts-activity'
        )
      end

      # Using admin? is generally discouraged because it does not check for
      # "admin_mode". In this case we are migrating code and check both, so
      # we should be good.
      # rubocop: disable Cop/UserAdmin
      if current_user&.admin?
        title = _('Admin')

        builder.add_secondary_menu_item(
          id: 'admin',
          title: title,
          active: active_nav_link?(controller: 'admin/dashboard'),
          icon: 'admin',
          href: admin_root_path,
          data: { qa_selector: 'admin_area_link', **menu_data_tracking_attrs(title) }
        )
      end

      if Gitlab::CurrentSettings.admin_mode
        if header_link?(:admin_mode)
          builder.add_secondary_menu_item(
            id: 'leave_admin_mode',
            title: _('Leave admin mode'),
            active: active_nav_link?(controller: 'admin/sessions'),
            icon: 'lock-open',
            href: destroy_admin_session_path,
            data: { method: 'post', **menu_data_tracking_attrs('leave_admin_mode') }
          )
        elsif current_user.admin?
          title = _('Enter admin mode')

          builder.add_secondary_menu_item(
            id: 'enter_admin_mode',
            title: title,
            active: active_nav_link?(controller: 'admin/sessions'),
            icon: 'lock',
            href: new_admin_session_path,
            data: { qa_selector: 'menu_item_link', qa_title: title, **menu_data_tracking_attrs(title) }
          )
        end
      end
      # rubocop: enable Cop/UserAdmin
    end

    def projects_menu_item_attrs
      {
        id: 'project',
        title: _('Projects'),
        icon: 'project',
        shortcut_class: 'dashboard-shortcuts-projects'
      }
    end

    def groups_menu_item_attrs
      {
        id: 'groups',
        title: _('Groups'),
        icon: 'group',
        shortcut_class: 'dashboard-shortcuts-groups'
      }
    end

    def topics_menu_item_attrs
      {
        id: 'topics',
        title: _('Topics'),
        icon: 'labels',
        shortcut_class: 'dashboard-shortcuts-topics'
      }
    end

    def snippets_menu_item_attrs
      {
        id: 'snippets',
        title: _('Snippets'),
        icon: 'snippet',
        shortcut_class: 'dashboard-shortcuts-snippets'
      }
    end

    def menu_data_tracking_attrs(label)
      tracking_attrs(
        "menu_#{label.underscore.parameterize(separator: '_')}",
        'click_dropdown',
        'navigation_top'
      )[:data] || {}
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
      builder = ::Gitlab::Nav::TopNavMenuBuilder.new
      projects_submenu_items(builder: builder)
      builder.build
    end

    def projects_submenu_items(builder:)
      title = _('View all projects')

      builder.add_primary_menu_item(
        id: 'your',
        title: title,
        href: dashboard_projects_path,
        data: { qa_selector: 'menu_item_link', qa_title: title, **menu_data_tracking_attrs(title) }
      )
    end

    def groups_submenu
      # These group links come from `app/views/layouts/nav/groups_dropdown/_show.html.haml`
      builder = ::Gitlab::Nav::TopNavMenuBuilder.new

      title = _('View all groups')

      builder.add_primary_menu_item(
        id: 'your',
        title: title,
        href: dashboard_groups_path,
        data: { qa_selector: 'menu_item_link', qa_title: title, **menu_data_tracking_attrs(title) }
      )
      builder.build
    end
  end
end

Nav::TopNavHelper.prepend_mod
