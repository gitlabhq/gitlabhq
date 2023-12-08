# frozen_string_literal: true

module NavHelper
  extend self

  def header_links
    @header_links ||= get_header_links
  end

  def header_link?(link)
    header_links.include?(link)
  end

  def page_with_sidebar_class
    class_name = page_gutter_class

    class_name << 'page-with-super-sidebar'
    class_name << 'page-with-super-sidebar-collapsed' if collapsed_super_sidebar?

    class_name -= ['right-sidebar-expanded'] if defined?(@right_sidebar) && !@right_sidebar

    class_name
  end

  def page_gutter_class
    moved_sidebar_enabled = current_controller?('merge_requests') && moved_mr_sidebar_enabled?

    if (page_has_markdown? || current_path?('projects/merge_requests#diffs')) && !current_controller?('conflicts')
      if cookies[:collapsed_gutter] == 'true'
        ["page-gutter", ('right-sidebar-collapsed' unless moved_sidebar_enabled).to_s]
      else
        ["page-gutter", ('right-sidebar-expanded' unless moved_sidebar_enabled).to_s]
      end
    elsif current_path?('jobs#show')
      %w[page-gutter build-sidebar right-sidebar-expanded]
    elsif current_controller?('wikis') && current_action?('show', 'create', 'edit', 'update', 'history', 'git_access', 'destroy', 'diff')
      %w[page-gutter wiki-sidebar right-sidebar-expanded]
    else
      []
    end
  end

  def user_dropdown_class
    class_names = []
    class_names << 'header-user-dropdown-toggle'
    class_names << 'impersonated-user' if session[:impersonator_id]

    class_names
  end

  def page_has_markdown?
    current_path?('projects/merge_requests#show') ||
      current_path?('projects/merge_requests/conflicts#show') ||
      current_path?('issues#show') ||
      current_path?('milestones#show') ||
      current_path?('issues#designs') ||
      current_path?('incidents#show')
  end

  def admin_monitoring_nav_links
    %w[system_info background_migrations background_jobs health_check]
  end

  def show_super_sidebar?(_user = current_user)
    # The new navigation is now enabled for everyone.
    # We are working on cleaning up the use of this helper and other related code.
    # See https://gitlab.com/groups/gitlab-org/-/epics/11875
    true
  end

  private

  def get_header_links
    links = if current_user
              [:user_dropdown]
            else
              [:sign_in]
            end

    if can?(current_user, :read_cross_project)
      links += [:issues, :merge_requests, :todos] if current_user.present?
    end

    if @project&.persisted? || can?(current_user, :read_cross_project)
      links << :search
    end

    if session[:impersonator_id]
      links << :admin_impersonation
    end

    if Gitlab::CurrentSettings.admin_mode && current_user_mode.admin_mode?
      links << :admin_mode
    end

    links
  end
end

NavHelper.prepend_mod_with('NavHelper')
