# Controller for viewing a file's blame
class BlameController < ApplicationController
  include ExtractsPath

  layout "project"

  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :assign_ref_vars

  def show
    @repo = @project.repo
    @blame = Grit::Blob.blame(@repo, @commit.id, @path)
  end
end
