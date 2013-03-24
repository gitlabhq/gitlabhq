class SnippetsController < ApplicationController
  before_filter :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow modify snippet
  before_filter :authorize_modify_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippets = Snippet.public.fresh.non_expired.page(params[:page]).per(20)
  end

  def user_index
    @user = User.find_by_username(params[:username])

    @snippets = @current_user.snippets.fresh.non_expired

    @snippets = case params[:scope]
                when 'public' then
                  @snippets.public
                when 'private' then
                  @snippets.private
                else
                  @snippets
                end

    @snippets = @snippets.page(params[:page]).per(20)
  end

  def new
    @snippet = PersonalSnippet.new
  end

  def create
    @snippet = PersonalSnippet.new(params[:personal_snippet])
    @snippet.author = current_user
    @snippet.save

    if @snippet.valid?
      redirect_to snippet_path(@snippet)
    else
      respond_with @snippet
    end
  end

  def edit
  end

  def update
    @snippet.update_attributes(params[:personal_snippet])

    if @snippet.valid?
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
    @snippet ||= PersonalSnippet.find(params[:id])
  end

  def authorize_modify_snippet!
    return render_404 unless can?(current_user, :modify_personal_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_personal_snippet, @snippet)
  end
end
