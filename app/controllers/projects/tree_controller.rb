# Controller for viewing a repository's file structure
class Projects::TreeController < Projects::ApplicationController
  include ExtractsPath

  before_action :require_non_empty_project, except: [:new, :create]
  before_action :assign_ref_vars
  before_action :authorize_download_code!

  def show
    return not_found! unless @repository.commit(@ref)

    if tree.entries.empty?
      if @repository.blob_at(@commit.id, @path)
        redirect_to(
          namespace_project_blob_path(@project.namespace, @project,
                                      File.join(@ref, @path))
        ) and return
      elsif @path.present?
        return not_found!
      end
    end

    respond_to do |format|
      format.html
      # Disable cache so browser history works
      format.js { no_cache_headers }
    end
  end
end
