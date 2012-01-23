class RepositoriesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :require_non_empty_project

  layout "project"

  def show
    @activities = @project.commits_with_refs(20)
  end

  def branches
    @branches = @project.repo.heads.sort_by(&:name)
  end

  def tags
    @tags = @project.repo.tags.sort_by(&:name).reverse
  end
end
