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

    if controller.controller_name == "snippets" || 
     controller.controller_name == "hooks" ||
     controller.controller_name == "deploy_keys" ||
     controller.controller_name == "team_members"
     "current"
    end
  end

  def tree_tab_class
    controller.controller_name == "refs" ? 
     "current" : nil
  end

  def commit_tab_class
    if controller.controller_name == "commits" || 
      controller.controller_name == "repositories" ||
      controller.controller_name == "protected_branches"
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
