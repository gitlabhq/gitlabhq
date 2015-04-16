# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blame = Gitlab::Git::Blame.new(@repository, @commit.id, @path)
    @blob = @blame.blob
  end
end
