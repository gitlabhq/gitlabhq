class Projects::WikisController < Projects::ApplicationController
  include PreviewMarkdown

  before_action :authorize_read_wiki!
  before_action :authorize_create_wiki!, only: [:edit, :create, :history]
  before_action :authorize_admin_wiki!, only: :destroy
  before_action :load_project_wiki

  def pages
    @wiki_pages = Kaminari.paginate_array(@project_wiki.pages).page(params[:page])
    @wiki_entries = WikiPage.group_by_directory(@wiki_pages)
  end

  def show
    @page = @project_wiki.find_page(params[:id], params[:version_id])

    if @page
      render 'show'
    elsif file = @project_wiki.find_file(params[:id], params[:version_id])
      response.headers['Content-Security-Policy'] = "default-src 'none'"
      response.headers['X-Content-Security-Policy'] = "default-src 'none'"

      send_data(
        file.raw_data,
        type: file.mime_type,
        disposition: 'inline',
        filename: file.name
      )
    else
      return render('empty') unless can?(current_user, :create_wiki, @project)

      @page = WikiPage.new(@project_wiki)
      @page.title = params[:id]

      render 'edit'
    end
  end

  def edit
    @page = @project_wiki.find_page(params[:id])
  end

  def update
    return render('empty') unless can?(current_user, :create_wiki, @project)

    @page = @project_wiki.find_page(params[:id])
    @page = WikiPages::UpdateService.new(@project, current_user, wiki_params).execute(@page)

    if @page.valid?
      redirect_to(
        project_wiki_path(@project, @page),
        notice: 'Wiki was successfully updated.'
      )
    else
      render 'edit'
    end
  rescue WikiPage::PageChangedError, WikiPage::PageRenameError => e
    @error = e
    render 'edit'
  end

  def create
    @page = WikiPages::CreateService.new(@project, current_user, wiki_params).execute

    if @page.persisted?
      redirect_to(
        project_wiki_path(@project, @page),
        notice: 'Wiki was successfully updated.'
      )
    else
      render action: "edit"
    end
  end

  def history
    @page = @project_wiki.find_page(params[:id])

    if @page
      @page_versions = Kaminari.paginate_array(@page.versions(page: params[:page].to_i),
                                               total_count: @page.count_versions)
        .page(params[:page])
    else
      redirect_to(
        project_wiki_path(@project, :home),
        notice: "Page not found"
      )
    end
  end

  def destroy
    @page = @project_wiki.find_page(params[:id])
    WikiPages::DestroyService.new(@project, current_user).execute(@page)

    redirect_to project_wiki_path(@project, :home),
                status: 302,
                notice: "Page was successfully deleted"
  end

  def git_access
  end

  private

  def load_project_wiki
    @project_wiki = ProjectWiki.new(@project, current_user)

    # Call #wiki to make sure the Wiki Repo is initialized
    @project_wiki.wiki

    @sidebar_page = @project_wiki.find_page('_sidebar', params[:version_id])

    unless @sidebar_page # Fallback to default sidebar
      @sidebar_wiki_entries = WikiPage.group_by_directory(@project_wiki.pages(limit: 15))
    end
  rescue ProjectWiki::CouldNotCreateWikiError
    flash[:notice] = "Could not create Wiki Repository at this time. Please try again later."
    redirect_to project_path(@project)
    return false
  end

  def wiki_params
    params.require(:wiki).permit(:title, :content, :format, :message, :last_commit_sha)
  end
end
