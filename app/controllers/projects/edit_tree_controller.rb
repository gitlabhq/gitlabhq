class Projects::EditTreeController < Projects::BaseTreeController
  before_filter :authorize_show_blob_edit!

  before_filter :blob
  before_filter :from_merge_request
  before_filter :after_edit_path
  before_filter :set_last_commit, only: [:show, :update]

  def show
    set_new_mr_vars
    params[:content] = @blob.data
  end

  def update
    update_new_mr(Files::UpdateService, @path)
  end

  def preview
    @content = params[:content]

    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3',
                            include_diff_info: true)
    @diff_lines = Gitlab::Diff::Parser.new.parse(diffy.diff.scan(/.*\n/))

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)
  end

  def after_edit_path
    @after_edit_path ||=
      if from_merge_request
        diffs_project_merge_request_path(from_merge_request.target_project, from_merge_request) +
          "#file-path-#{hexdigest(@path)}"
      else
        project_blob_path(@project, @id)
      end
  end

  def set_last_commit
    @last_commit = Gitlab::Git::Commit.
      last_for_path(@repository, @ref, @path).sha
  end
end
