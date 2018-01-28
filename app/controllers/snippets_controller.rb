class SnippetsController < ApplicationController
  include RendersNotes
  include ToggleAwardEmoji
  include SpammableActions
  include SnippetsActions
  include RendersBlob
  include PreviewMarkdown

  before_action :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow read snippet
  before_action :authorize_read_snippet!, only: [:show, :raw]

  # Allow modify snippet
  before_action :authorize_update_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_snippet!, only: [:destroy]

  skip_before_action :authenticate_user!, only: [:index, :show, :raw]

  layout 'snippets'
  respond_to :html

  def index
    if params[:username].present?
      @user = User.find_by(username: params[:username])

      return render_404 unless @user

      @snippets = SnippetsFinder.new(current_user, author: @user, scope: params[:scope])
        .execute.page(params[:page])

      render 'index'
    else
      redirect_to(current_user ? dashboard_snippets_path : explore_snippets_path)
    end
  end

  def new
    @snippet = PersonalSnippet.new
  end

  def create
    create_params = snippet_params.merge(spammable_params)

    @snippet = CreateSnippetService.new(nil, current_user, create_params).execute

    move_temporary_files if @snippet.valid? && params[:files]

    recaptcha_check_with_fallback { render :new }
  end

  def update
    update_params = snippet_params.merge(spammable_params)

    UpdateSnippetService.new(nil, current_user, @snippet, update_params).execute

    recaptcha_check_with_fallback { render :edit }
  end

  def show
    blob = @snippet.blob
    conditionally_expand_blob(blob)

    @note = Note.new(noteable: @snippet)
    @noteable = @snippet

    @discussions = @snippet.discussions
    @notes = prepare_notes_for_rendering(@discussions.flat_map(&:notes), @noteable)

    respond_to do |format|
      format.html do
        render 'show'
      end

      format.json do
        render_blob_json(blob)
      end
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_personal_snippet, @snippet)

    @snippet.destroy

    redirect_to snippets_path, status: 302
  end

  protected

  def snippet
    @snippet ||= PersonalSnippet.find_by(id: params[:id])
  end

  alias_method :awardable, :snippet
  alias_method :spammable, :snippet

  def spammable_path
    snippet_path(@snippet)
  end

  def authorize_read_snippet!
    return if can?(current_user, :read_personal_snippet, @snippet)

    if current_user
      render_404
    else
      authenticate_user!
    end
  end

  def authorize_update_snippet!
    return render_404 unless can?(current_user, :update_personal_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_personal_snippet, @snippet)
  end

  def snippet_params
    params.require(:personal_snippet).permit(:title, :content, :file_name, :private, :visibility_level, :description)
  end

  def move_temporary_files
    params[:files].each do |file|
      FileMover.new(file, @snippet).execute
    end
  end
end
