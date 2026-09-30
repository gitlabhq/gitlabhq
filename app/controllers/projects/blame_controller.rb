# frozen_string_literal: true

# Controller for viewing a file's blame
class Projects::BlameController < Projects::ApplicationController
  include ExtractsPath
  include RedirectsForMissingPathOnTree
  include HandlesGitalyErrors

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_code!
  before_action :load_blob
  before_action :require_non_binary_blob

  feature_category :source_code_management
  urgency :low, [:show]

  def show
    @ref_type = ref_type
  end

  private

  def load_blob
    @blob = @repository.blob_at(@commit.id, @path)

    return if @blob

    redirect_to_tree_root_for_missing_path(@project, @ref, @path)
  end

  def require_non_binary_blob
    return unless @blob.binary?

    redirect_to project_blob_path(@project, File.join(@ref, @path)),
      notice: _('Blame for binary files is not supported.')
  end
end

Projects::BlameController.prepend_mod
