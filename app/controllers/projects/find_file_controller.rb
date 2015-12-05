# Controller for viewing a repository's file structure
class Projects::FindFileController < Projects::ApplicationController
  include ExtractsPath
  include ActionView::Helpers::SanitizeHelper
  include TreeHelper
  before_action :assign_ref_vars

  def show
    return render_404 unless @repository.commit(@ref)

    @url = namespace_project_files_path(@project.namespace, @project, @ref, @options.merge(format: :json))
    @blobUrlTemplate = namespace_project_blob_path(project.namespace, project, tree_join('%id', '%path'))

    respond_to do |format|
      format.html
    end
  end

  def list
    filePathes = Grit::Repo.new(@repo.path_to_repo, { is_bare: true }).lstree(@ref, {recursive: true, }).map do | file |
      file[:path]
    end

    respond_to do |format|
      format.json { render json: filePathes }
    end
  end
end
