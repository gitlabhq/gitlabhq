class Projects::SnippetsController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow read any snippet
  before_filter :authorize_read_project_snippet!

  # Allow write(create) snippet
  before_filter :authorize_write_project_snippet!, only: [:new, :create]

  # Allow modify snippet
  before_filter :authorize_modify_project_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_project_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippets = @project.snippets.fresh.non_expired
  end

  def new
    @snippet = @project.snippets.build
  end

  def create
    @snippet = @project.snippets.build(params[:project_snippet])
    @snippet.author = current_user

    if @snippet.save
      redirect_to project_snippet_path(@project, @snippet)
    else
      respond_with(@snippet)
    end
  end

  def edit
  end

  def update
    if @snippet.update_attributes(params[:project_snippet])
      redirect_to project_snippet_path(@project, @snippet)
    else
      respond_with(@snippet)
    end
  end

  def show
    @note = @project.notes.new(noteable: @snippet)
    @notes = @snippet.notes.fresh
    @noteable = @snippet
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_project_snippet, @snippet)

    @snippet.destroy

    redirect_to project_snippets_path(@project)
  end

  def raw
    send_data(
      @snippet.content,
      type: "text/plain",
      disposition: 'inline',
      filename: @snippet.file_name
    )
  end

  protected

  def snippet
    @snippet ||= @project.snippets.find(params[:id])
  end

  def authorize_modify_project_snippet!
    return render_404 unless can?(current_user, :modify_project_snippet, @snippet)
  end

  def authorize_admin_project_snippet!
    return render_404 unless can?(current_user, :admin_project_snippet, @snippet)
  end

  def module_enabled
    return render_404 unless @project.snippets_enabled
  end
end
