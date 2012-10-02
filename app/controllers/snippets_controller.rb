class SnippetsController < ProjectResourceController
  before_filter :snippet, only: [:show, :edit, :destroy, :update, :raw]

  # Allow read any snippet
  before_filter :authorize_read_snippet!

  # Allow write(create) snippet
  before_filter :authorize_write_snippet!, only: [:new, :create]

  # Allow modify snippet
  before_filter :authorize_modify_snippet!, only: [:edit, :update]

  # Allow destroy snippet
  before_filter :authorize_admin_snippet!, only: [:destroy]

  respond_to :html

  def index
    @snippets = @project.snippets
  end

  def new
    @snippet = @project.snippets.new
  end

  def create
    @snippet = @project.snippets.new(params[:snippet])
    @snippet.author = current_user
    @snippet.save

    if @snippet.valid?
      redirect_to [@project, @snippet]
    else
      respond_with(@snippet)
    end
  end

  def edit
  end

  def update
    @snippet.update_attributes(params[:snippet])

    if @snippet.valid?
      redirect_to [@project, @snippet]
    else
      respond_with(@snippet)
    end
  end

  def show
    @note = @project.notes.new(noteable: @snippet)
  end

  def destroy
    return access_denied! unless can?(current_user, :admin_snippet, @snippet)

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

  def authorize_modify_snippet!
    return render_404 unless can?(current_user, :modify_snippet, @snippet)
  end

  def authorize_admin_snippet!
    return render_404 unless can?(current_user, :admin_snippet, @snippet)
  end
end
