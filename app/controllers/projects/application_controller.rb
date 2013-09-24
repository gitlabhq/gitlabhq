class Projects::ApplicationController < ApplicationController
  before_filter :project
  before_filter :repository
  layout :determine_layout

  def authenticate_user!
    # Restrict access to Projects area only
    # for non-signed users
    if !current_user
      id = params[:project_id] || params[:id]
      @project = Project.find_with_namespace(id)

      return if @project && @project.public
    end

    super
  end

  def determine_layout
    if current_user
      'projects'
    else
      'public_projects'
    end
  end
end
