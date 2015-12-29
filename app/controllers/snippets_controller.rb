class SnippetsController < ApplicationController
  before_action :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow read snippet
  before_action :authorize_read_snippet!, only: [:show, :raw]

  # Allow modify snippet
  before_action :authorize_update_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_action :authorize_admin_snippet!, only: [:destroy]

  skip_before_action :authenticate_user!, only: [:index, :user_index, :show, :raw]

  layout 'snippets'
  respond_to :html

  def index
    if params[:username].present?
      @user = User.find_by(username: params[:username])

      render_404 and return unless @user

      @snippets = SnippetsFinder.new.execute(current_user, {
        filter: :by_user,
        user: @user,
        scope: params[:scope] }).
      page(params[:page]).per(PER_PAGE)

      render 'index'
    else
      redirect_to(current_user ? dashboard_snippets_path : explore_snippets_path)
    end
  end

  def new
    @snippet = PersonalSnippet.new
  end

  def create
    @snippet = CreateSnippetService.new(nil, current_user,
                                        snippet_params).execute

    respond_with @snippet.becomes(Snippet)
  end

  def edit
  end

  def update
    UpdateSnippetService.new(nil, current_user, @snippet,
                             snippet_params).execute
    respond_with @snippet.becomes(Snippet)
  end

  def show
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_personal_snippet, @snippet)

    @snippet.destroy

    redirect_to snippets_path
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
    @snippet ||= if current_user
                   PersonalSnippet.where("author_id = ? OR visibility_level IN (?)",
                     current_user.id,
                     [Snippet::PUBLIC, Snippet::INTERNAL]).
                     find(params[:id])
                 else
                   PersonalSnippet.find(params[:id])
                 end
  end

  def authorize_read_snippet!
    authenticate_user! unless can?(current_user, :read_personal_snippet, @snippet)
  end

  def authorize_update_snippet!
    return render_404 unless can?(current_user, :update_personal_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_personal_snippet, @snippet)
  end

  def snippet_params
    params.require(:personal_snippet).permit(:title, :content, :file_name, :private, :visibility_level)
  end
end
