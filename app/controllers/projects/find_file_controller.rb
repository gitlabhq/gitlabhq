# frozen_string_literal: true

# Controller for viewing a repository's file structure
class Projects::FindFileController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper
  include TreeHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_read_code!

  feature_category :source_code_management
  urgency :low, [:show, :list]

  def show
    return render_404 unless @commit

    @ref_type = ref_type

    respond_to do |format|
      format.html
    end
  end

  def list
    file_paths = @repo.ls_files(@commit.id)

    respond_to do |format|
      format.json { render json: file_paths }
    end
  end
end
