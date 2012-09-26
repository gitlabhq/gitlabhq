module TabHelper
  def tab_class(tab_key)
    active = case tab_key

             # Project Area
             when :wall; wall_tab?
             when :wiki; controller.controller_name == "wikis"
             when :issues; issues_tab?
             when :network; current_page?(controller: "projects", action: "graph", id: @project)
             when :merge_requests; controller.controller_name == "merge_requests"

             # Dashboard Area
             when :help; controller.controller_name == "help"
             when :search; current_page?(search_path)
             when :dash_issues; current_page?(dashboard_issues_path)
             when :dash_mr; current_page?(dashboard_merge_requests_path)
             when :root; current_page?(dashboard_path) || current_page?(root_path)

             # Profile Area
             when :profile;  current_page?(controller: "profile", action: :show)
             when :history;  current_page?(controller: "profile", action: :history)
             when :account;  current_page?(controller: "profile", action: :account)
             when :token;    current_page?(controller: "profile", action: :token)
             when :design;   current_page?(controller: "profile", action: :design)
             when :ssh_keys; controller.controller_name == "keys"

             # Admin Area
             when :admin_root;     controller.controller_name == "dashboard"
             when :admin_users;    controller.controller_name == 'users'
             when :admin_projects; controller.controller_name == "projects"
             when :admin_hooks;    controller.controller_name == 'hooks'
             when :admin_resque;   controller.controller_name == 'resque'
             when :admin_logs;   controller.controller_name == 'logs'

             else
               false
             end
    active ? "current" : nil
  end

  def issues_tab?
    controller.controller_name == "issues" || controller.controller_name == "milestones"
  end

  def wall_tab?
    current_page?(controller: "projects", action: "wall", id: @project)
  end

  def project_tab_class
    [:show, :files, :edit, :update].each do |action|
      return "current" if current_page?(controller: "projects", action: action, id: @project)
    end

    if ['snippets', 'hooks', 'deploy_keys', 'team_members'].include? controller.controller_name
     "current"
    end
  end

  def tree_tab_class
    controller.controller_name == "refs" ? "current" : nil
  end

  def commit_tab_class
    if ['commits', 'repositories', 'protected_branches'].include? controller.controller_name
      "current"
    end
  end

  def branches_tab_class
    if current_page?(branches_project_repository_path(@project)) ||
      controller.controller_name == "protected_branches" ||
      current_page?(project_repository_path(@project))
      'active'
    end
  end
end
