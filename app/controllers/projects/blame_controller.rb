# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  before_filter :require_non_empty_project
  before_filter :assign_ref_vars
  before_filter :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)
    @blame = Gitlab::Git::Blame.new(project.repository, @commit.id, @path)
  end
end
