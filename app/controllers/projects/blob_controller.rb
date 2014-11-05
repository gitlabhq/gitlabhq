# Controller for viewing a file's blame
class Projects::BlobController < Projects::ApplicationController
  include ExtractsPath

  # Authorize
  before_filter :authorize_download_code!
  before_filter :require_non_empty_project
  before_filter :authorize_push_code!, only: [:destroy]

  before_filter :blob

  def show
  end

  def destroy
    result = Files::DeleteService.new(@project, current_user, params, @ref, @path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"
      redirect_to project_tree_path(@project, @ref)
    else
      flash[:alert] = result[:message]
      render :show
    end
  end

  def diff
    @form = UnfoldForm.new(params)
    @lines = @blob.data.lines[@form.since - 1..@form.to - 1]

    if @form.bottom?
      @match_line = ''
    else
      lines_length = @lines.length - 1
      line = [@form.since, lines_length].join(',')
      @match_line = "@@ -#{line}+#{line} @@"
    end

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)

    if @blob
      @blob
    elsif tree.entries.any?
      redirect_to project_tree_path(@project, File.join(@ref, @path)) and return
    else
      return not_found!
    end
  end
end
