# frozen_string_literal: true

module NavHelper
  def header_links
    @header_links ||= get_header_links
  end

  def header_link?(link)
    header_links.include?(link)
  end

  def page_with_sidebar_class
    class_name = page_gutter_class
    class_name << 'page-with-contextual-sidebar' if defined?(@left_sidebar) && @left_sidebar
    class_name << 'page-with-icon-sidebar' if collapsed_sidebar? && @left_sidebar
    class_name -= ['right-sidebar-expanded'] if defined?(@right_sidebar) && !@right_sidebar

    class_name
  end

  def page_gutter_class
    if page_has_markdown?
      if cookies[:collapsed_gutter] == 'true'
        %w[page-gutter right-sidebar-collapsed]
      else
        %w[page-gutter right-sidebar-expanded]
      end
    elsif current_path?('jobs#show')
      %w[page-gutter build-sidebar right-sidebar-expanded]
    elsif current_controller?('wikis') && current_action?('show', 'create', 'edit', 'update', 'history', 'git_access', 'destroy')
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

  def has_extra_nav_icons?
    Gitlab::Sherlock.enabled? || can?(current_user, :read_instance_statistics) || current_user.admin?
  end

  def page_has_markdown?
    current_path?('merge_requests#show') ||
      current_path?('projects/merge_requests/conflicts#show') ||
      current_path?('issues#show') ||
      current_path?('milestones#show')
  end

  def admin_monitoring_nav_links
    %w(system_info background_jobs logs health_check requests_profiles)
  end

  def group_issues_sub_menu_items
    %w(groups#issues labels#index milestones#index boards#index boards#show)
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

    if Feature.enabled?(:user_mode_in_session)
      if current_user_mode.admin_mode?
        links << :admin_mode
      end
    end

    links
  end
end

NavHelper.prepend_if_ee('EE::NavHelper')
