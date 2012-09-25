class ProjectController < ApplicationController
  before_filter :project
  # Authorize
  before_filter :add_project_abilities

  layout :determine_layout

  protected
  def determine_layout
    if @project && !@project.new_record?
      'project'
    else
      'application'
    end
  end
end
