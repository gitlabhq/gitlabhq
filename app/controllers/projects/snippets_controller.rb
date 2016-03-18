class Projects::SnippetsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow read any snippet
  before_action :authorize_read_project_snippet!

  # Allow write(create) snippet
  before_action :authorize_create_project_snippet!, only: [:new, :create]

  # Allow modify snippet
  before_action :authorize_update_project_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_project_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippets = SnippetsFinder.new.execute(current_user, {
      filter: :by_project,
      project: @project
    })
    @snippets = @snippets.page(params[:page]).per(PER_PAGE)
  end

  def new
    @snippet = @noteable = @project.snippets.build
  end

  def create
    @snippet = CreateSnippetService.new(@project, current_user,
                                        snippet_params).execute

    if @snippet.valid?
      respond_with(@snippet,
                   location: namespace_project_snippet_path(@project.namespace,
                                                            @project, @snippet))
    else
      render :new
    end
  end

  def edit
  end

  def update
    UpdateSnippetService.new(project, current_user, @snippet,
                             snippet_params).execute
    respond_with(@snippet,
                 location: namespace_project_snippet_path(@project.namespace,
                                                          @project, @snippet))
  end

  def show
    @note = @project.notes.new(noteable: @snippet)
    @notes = @snippet.notes.fresh
    @noteable = @snippet
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_project_snippet, @snippet)

    @snippet.destroy

    redirect_to namespace_project_snippets_path(@project.namespace, @project)
  end

  def raw
    send_data(
      @snippet.content,
      type: 'text/plain; charset=utf-8',
      disposition: 'inline',
      filename: @snippet.sanitized_file_name
    )
  end

  protected

  def snippet
    @snippet ||= @project.snippets.find(params[:id])
  end

  def authorize_update_project_snippet!
    return render_404 unless can?(current_user, :update_project_snippet, @snippet)
  end

  def authorize_admin_project_snippet!
    return render_404 unless can?(current_user, :admin_project_snippet, @snippet)
  end

  def module_enabled
    return render_404 unless @project.snippets_enabled
  end

  def snippet_params
    params.require(:project_snippet).permit(:title, :content, :file_name, :private, :visibility_level)
  end
end
