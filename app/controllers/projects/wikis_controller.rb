require 'project_wiki'

class Projects::WikisController < Projects::ApplicationController
  before_filter :authorize_read_wiki!
  before_filter :authorize_write_wiki!, only: [:edit, :create, :history]
  before_filter :authorize_admin_wiki!, only: :destroy
  before_filter :load_project_wiki

  def pages
    @wiki_pages = Kaminari.paginate_array(@project_wiki.pages).page(params[:page]).per(30)
  end

  def show
    @page = @project_wiki.find_page(params[:id], params[:version_id])

    if @page
      render 'show'
    elsif file = @project_wiki.find_file(params[:id], params[:version_id])
       if file.on_disk?
         send_file file.on_disk_path, disposition: 'inline'
       else
         send_data(
           file.raw_data,
           type: file.mime_type,
           disposition: 'inline',
           filename: file.name
         )
       end
    else
      return render('empty') unless can?(current_user, :write_wiki, @project)
      @page = WikiPage.new(@project_wiki)
      @page.title = params[:id]

      render 'edit'
    end
  end

  def edit
    @page = @project_wiki.find_page(params[:id])
  end

  def update
    @page = @project_wiki.find_page(params[:id])

    return render('empty') unless can?(current_user, :write_wiki, @project)

    if @page.update(content, format, message)
      redirect_to [@project, @page], notice: 'Wiki was successfully updated.'
    else
      render 'edit'
    end
  end

  def create
    @page = WikiPage.new(@project_wiki)

    if @page.create(wiki_params)
      redirect_to project_wiki_path(@project, @page), notice: 'Wiki was successfully updated.'
    else
      render action: "edit"
    end
  end

  def history
    @page = @project_wiki.find_page(params[:id])

    unless @page
      redirect_to(project_wiki_path(@project, :home), notice: "Page not found")
    end
  end

  def destroy
    @page = @project_wiki.find_page(params[:id])
    @page.delete if @page

    redirect_to project_wiki_path(@project, :home), notice: "Page was successfully deleted"
  end

  def git_access
  end

  private

  def load_project_wiki
    @project_wiki = ProjectWiki.new(@project, current_user)

    # Call #wiki to make sure the Wiki Repo is initialized
    @project_wiki.wiki
  rescue ProjectWiki::CouldNotCreateWikiError => ex
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
