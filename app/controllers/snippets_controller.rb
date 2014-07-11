class SnippetsController < ApplicationController
  before_filter :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow modify snippet
  before_filter :authorize_modify_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_snippet!, only: [:destroy]

  before_filter :set_title

  respond_to :html

  layout 'navless'

  def index
    @snippets = Snippet.are_public.fresh.non_expired.page(params[:page]).per(20)
  end

  def user_index
    @user = User.find_by(username: params[:username])

    render_404 and return unless @user

    @snippets = @user.snippets.fresh.non_expired

    if @user == current_user
      @snippets = case params[:scope]
                  when 'are_public' then
                    @snippets.are_public
                  when 'are_private' then
                    @snippets.are_private
                  else
                    @snippets
                  end
    else
      @snippets = @snippets.are_public
    end

    @snippets = @snippets.page(params[:page]).per(20)

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
      type: "text/plain",
      disposition: 'inline',
      filename: @snippet.file_name
    )
  end

  protected

  def snippet
    @snippet ||= PersonalSnippet.where('author_id = :user_id or private is false', user_id: current_user.id).find(params[:id])
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
    params.require(:personal_snippet).permit(:title, :content, :file_name, :private)
  end
end
