# frozen_string_literal: true

# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    @blob = @repository.blob_at(@commit.id, @path)

    return render_404 unless @blob

    environment_params = @repository.branch_exists?(@ref) ? { ref: @ref } : { commit: @commit }
    @environment = EnvironmentsFinder.new(@project, current_user, environment_params).execute.last

    @blame_groups = Gitlab::Blame.new(@blob, @commit).groups
  end
end
