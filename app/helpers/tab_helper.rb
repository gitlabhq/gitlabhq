module TabHelper
  def issues_tab?
    controller.controller_name == "issues" || controller.controller_name == "milestones"
  end

  def wall_tab?
    current_page?(:controller => "projects", :action => "wall", :id => @project)
  end

  def project_tab_class
    [:show, :files, :team, :edit, :update].each do |action|
      return "current" if current_page?(:controller => "projects", :action => action, :id => @project)
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
