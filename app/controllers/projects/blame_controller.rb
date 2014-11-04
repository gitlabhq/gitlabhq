# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project

  def show
    @show_blob_edit = can_show_blob_edit?
    @blob = @repository.blob_at(@commit.id, @path)
    @blame = Gitlab::Git::Blame.new(project.repository, @commit.id, @path)
  end
end
