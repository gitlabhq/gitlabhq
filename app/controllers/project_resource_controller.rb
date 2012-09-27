class ProjectResourceController < ApplicationController
  before_filter :project
  # Authorize
  before_filter :add_project_abilities
end
