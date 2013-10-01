# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  def show
    @blob = Gitlab::Git::Blob.find(@repository, @commit.id, @path)
    @blame = Gitlab::Git::Blame.new(project.repository, @commit.id, @path)
  end
end
