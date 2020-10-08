# frozen_string_literal: true

# Controller for viewing a repository's file structure
class Projects::FindFileController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper
  include TreeHelper

  before_action :require_non_empty_project
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  feature_category :source_code_management

  def show
    return render_404 unless @repository.commit(@ref)

    respond_to do |format|
      format.html
    end
  end

  def list
    file_paths = @repo.ls_files(@ref)

    respond_to do |format|
      format.json { render json: file_paths }
    end
  end
end
