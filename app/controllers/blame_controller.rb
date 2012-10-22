# Controller for viewing a file's blame
class BlameController < ProjectResourceController
  include ExtractsPath

  # Authorize
  before_filter :authorize_read_project!
  before_filter :authorize_code_access!
  before_filter :require_non_empty_project

  before_filter :assign_ref_vars

  def show
    @repo = @project.repo
    @blame = Grit::Blob.blame(@repo, @commit.id, @path)
  end
end
