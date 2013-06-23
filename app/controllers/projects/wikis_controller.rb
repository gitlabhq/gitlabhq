class Projects::WikisController < Projects::ApplicationController
  before_filter :authorize_read_wiki!
  before_filter :authorize_write_wiki!, only: [:edit, :create, :history]
  before_filter :authorize_admin_wiki!, only: :destroy
  before_filter :load_gollum_wiki

  def pages
    @wiki_pages = @gollum_wiki.pages
  end

  def show
    @wiki = @gollum_wiki.find_page(params[:id], params[:version_id])

    if @wiki
      render 'show'
    else
      return render('empty') unless can?(current_user, :write_wiki, @project)
      @wiki = WikiPage.new(@gollum_wiki)
      @wiki.title = params[:id]

      render 'edit'
    end
  end

  def edit
    @wiki = @gollum_wiki.find_page(params[:id])
  end

  def update
    @wiki = @gollum_wiki.find_page(params[:id])

    return render('empty') unless can?(current_user, :write_wiki, @project)

    if @wiki.update(content, format, message)
      redirect_to [@project, @wiki], notice: 'Wiki was successfully updated.'
    else
      render 'edit'
    end
  end

  def create
    @wiki = WikiPage.new(@gollum_wiki)

    if @wiki.create(wiki_params)
      redirect_to project_wiki_path(@project, @wiki), notice: 'Wiki was successfully updated.'
    else
      render action: "edit"
    end
  end

  def history
    @wiki = @gollum_wiki.find_page(params[:id])

    redirect_to(project_wiki_path(@project, :home), notice: "Page not found") unless @wiki
  end

  def destroy
    @wiki = @gollum_wiki.find_page(params[:id])
    @wiki.delete if @wiki
    redirect_to project_wiki_path(@project, :home), notice: "Page was successfully deleted"
  end

  def git_access
  end

  private

  def load_gollum_wiki
    @gollum_wiki = GollumWiki.new(@project, current_user)

    # Call #wiki to make sure the Wiki Repo is initialized
    @gollum_wiki.wiki
  rescue GollumWiki::CouldNotCreateWikiError => ex
    flash[:notice] = "Could not create Wiki Repository at this time. Please try again later."
    redirect_to @project
    return false
  end

  def wiki_params
    params[:wiki].slice(:title, :content, :format, :message)
  end

  def content
    params[:wiki][:content]
  end

  def format
    params[:wiki][:format]
  end

  def message
    params[:wiki][:message]
  end

end
