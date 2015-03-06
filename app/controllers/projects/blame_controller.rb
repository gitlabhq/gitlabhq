# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  before_filter :require_non_empty_project
  before_filter :assign_ref_vars
  before_filter :authorize_download_code!

  def show
    @blame = Gitlab::Git::Blame.new(@repository, @commit.id, @path)
    @blob = @blame.blob
  end
end
