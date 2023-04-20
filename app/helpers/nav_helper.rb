# frozen_string_literal: true

module NavHelper
  extend self

  def header_links
    @header_links ||= get_header_links
  end

  def header_link?(link)
    header_links.include?(link)
  end

  def page_has_sidebar?
    defined?(@left_sidebar) && @left_sidebar
  end

  def page_has_collapsed_sidebar?
    page_has_sidebar? && collapsed_sidebar?
  end

  def page_has_collapsed_super_sidebar?
    page_has_sidebar? && collapsed_super_sidebar?
  end

  def page_with_sidebar_class
    class_name = page_gutter_class

    if show_super_sidebar?
      class_name << 'page-with-super-sidebar' if page_has_sidebar?
      class_name << 'page-with-super-sidebar-collapsed' if page_has_collapsed_super_sidebar?
    else
      class_name << 'page-with-contextual-sidebar' if page_has_sidebar?
      class_name << 'page-with-icon-sidebar' if page_has_collapsed_sidebar?
    end

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

  def nav_control_class
    "nav-control" if current_user
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
    %w(system_info background_migrations background_jobs health_check)
  end

  def admin_analytics_nav_links
    %w(dev_ops_report usage_trends)
  end

  def show_super_sidebar?(user = current_user)
    # The new sidebar is not enabled for anonymous use
    # Once we enable the new sidebar by default, this
    # should return true
    return false unless user

    Feature.enabled?(:super_sidebar_nav, user) && user.use_new_navigation
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
