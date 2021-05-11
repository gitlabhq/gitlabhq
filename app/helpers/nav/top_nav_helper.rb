# frozen_string_literal: true

module Nav
  module TopNavHelper
    PROJECTS_VIEW = :projects

    def top_nav_view_model(project:)
      builder = ::Gitlab::Nav::TopNavViewModelBuilder.new

      if current_user
        build_view_model(builder: builder, project: project)
      else
        build_anonymous_view_model(builder: builder)
      end

      builder.build
    end

    private

    def build_anonymous_view_model(builder:)
      # These come from `app/views/layouts/nav/_explore.html.ham`
      # TODO: We will move the rest of them shortly
      #   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56587
      if explore_nav_link?(:projects)
        builder.add_primary_menu_item(
          **projects_menu_item_attrs.merge({
            active: active_nav_link?(path: ['dashboard#show', 'root#show', 'projects#trending', 'projects#starred', 'projects#index']),
            href: explore_root_path
          })
        )
      end
    end

    def build_view_model(builder:, project:)
      # These come from `app/views/layouts/nav/_dashboard.html.haml`
      if dashboard_nav_link?(:projects)
        current_item = project ? current_project(project: project) : {}

        builder.add_primary_menu_item(
          **projects_menu_item_attrs.merge({
            active: active_nav_link?(path: ['root#index', 'projects#trending', 'projects#starred', 'dashboard/projects#index']),
            css_class: 'qa-projects-dropdown',
            data: { track_label: "projects_dropdown", track_event: "click_dropdown", track_experiment: "new_repo" },
            view: PROJECTS_VIEW
          })
        )
        builder.add_view(PROJECTS_VIEW, container_view_props(current_item: current_item, submenu: projects_submenu))
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
    end

    def projects_menu_item_attrs
      {
        id: 'project',
        title: _('Projects'),
        icon: 'project'
      }
    end

    def container_view_props(current_item:, submenu:)
      {
        namespace: 'projects',
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

    def projects_submenu
      # These project links come from `app/views/layouts/nav/projects_dropdown/_show.html.haml`
      builder = ::Gitlab::Nav::TopNavMenuBuilder.new
      builder.add_primary_menu_item(id: 'your', title: _('Your projects'), href: dashboard_projects_path)
      builder.add_primary_menu_item(id: 'starred', title: _('Starred projects'), href: starred_dashboard_projects_path)
      builder.add_primary_menu_item(id: 'explore', title: _('Explore projects'), href: explore_root_path)
      builder.add_secondary_menu_item(id: 'create', title: _('Create new project'), href: new_project_path)
      builder.build
    end
  end
end

Nav::TopNavHelper.prepend_mod
