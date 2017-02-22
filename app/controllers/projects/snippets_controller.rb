class Projects::SnippetsController < Projects::ApplicationController
  include ToggleAwardEmoji
  include SpammableActions

  before_action :module_enabled
  before_action :snippet, only: [:show, :edit, :destroy, :update, :raw, :toggle_award_emoji, :mark_as_spam]

  # Allow read any snippet
  before_action :authorize_read_project_snippet!, except: [:new, :create, :index]

  # Allow write(create) snippet
  before_action :authorize_create_project_snippet!, only: [:new, :create]

  # Allow modify snippet
  before_action :authorize_update_project_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_project_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippets = SnippetsFinder.new.execute(
      current_user,
      filter: :by_project,
      project: @project,
      scope: params[:scope]
    )
    @snippets = @snippets.page(params[:page])
    if @snippets.out_of_range? && @snippets.total_pages != 0
      redirect_to namespace_project_snippets_path(page: @snippets.total_pages)
    end
  end

  def new
    @snippet = @noteable = @project.snippets.build
  end

  def create
    create_params = snippet_params.merge(spammable_params)

    @snippet = CreateSnippetService.new(@project, current_user, create_params).execute

    recaptcha_check_with_fallback { render :new }
  end

  def edit
  end

  def update
    update_params = snippet_params.merge(spammable_params)

    UpdateSnippetService.new(project, current_user, @snippet, update_params).execute

    recaptcha_check_with_fallback { render :edit }
  end

  def show
    @note = @project.notes.new(noteable: @snippet)
    @notes = Banzai::NoteRenderer.render(@snippet.notes.fresh, @project, current_user)
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
  alias_method :awardable, :snippet
  alias_method :spammable, :snippet

  def authorize_read_project_snippet!
    return render_404 unless can?(current_user, :read_project_snippet, @snippet)
  end

  def authorize_update_project_snippet!
    return render_404 unless can?(current_user, :update_project_snippet, @snippet)
  end

  def authorize_admin_project_snippet!
    return render_404 unless can?(current_user, :admin_project_snippet, @snippet)
  end

  def module_enabled
    return render_404 unless @project.feature_available?(:snippets, current_user)
  end

  def snippet_params
    params.require(:project_snippet).permit(:title, :content, :file_name, :private, :visibility_level)
  end
end
