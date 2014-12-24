class SnippetsController < ApplicationController
  before_filter :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow modify snippet
  before_filter :authorize_modify_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_snippet!, only: [:destroy]

  before_filter :set_title

  skip_before_filter :authenticate_user!, only: [:index, :user_index, :show, :raw]

  respond_to :html

  layout :determine_layout

  def index
    @snippets = SnippetsFinder.new.execute(current_user, filter: :all).page(params[:page]).per(20)
  end

  def user_index
    @user = User.find_by(username: params[:username])

    render_404 and return unless @user

    @snippets = SnippetsFinder.new.execute(current_user, {
      filter: :by_user,
      user: @user,
      scope: params[:scope]}).
    page(params[:page]).per(20)

    if @user == current_user
      render 'current_user_index'
    else
      render 'user_index'
    end
  end

  def new
    @snippet = PersonalSnippet.new
  end

  def create
    @snippet = PersonalSnippet.new(snippet_params)
    @snippet.author = current_user

    if @snippet.save
      redirect_to snippet_path(@snippet)
    else
      respond_with @snippet
    end
  end

  def edit
  end

  def update
    if @snippet.update_attributes(snippet_params)
      redirect_to snippet_path(@snippet)
    else
      respond_with @snippet
    end
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
                   PersonalSnippet.are_public.find(params[:id])
                 end
  end

  def authorize_modify_snippet!
    return render_404 unless can?(current_user, :modify_personal_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_personal_snippet, @snippet)
  end

  def set_title
    @title = 'Snippets'
  end

  def snippet_params
    params.require(:personal_snippet).permit(:title, :content, :file_name, :private, :visibility_level)
  end

  def determine_layout
    current_user ? 'navless' : 'public_users'
  end
end
