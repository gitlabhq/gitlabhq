require 'project_wiki'

class Projects::WikisController < Projects::ApplicationController
  before_action :authorize_read_wiki!
  before_action :authorize_create_wiki!, only: [:edit, :create, :history]
  before_action :authorize_admin_wiki!, only: :destroy
  before_action :load_project_wiki

  def pages
    @wiki_pages = Kaminari.paginate_array(@project_wiki.pages).page(params[:page])
  end

  def show
    @page = @project_wiki.find_page(params[:id], params[:version_id])

    if @page
      render 'show'
    elsif file = @project_wiki.find_file(params[:id], params[:version_id])
      response.headers['Content-Security-Policy'] = "default-src 'none'"
      response.headers['X-Content-Security-Policy'] = "default-src 'none'"

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

    if @page = WikiPages::UpdateService.new(@project, current_user, wiki_params).execute(@page)
      # Triggers repository update on secondary nodes when Geo is enabled
      Gitlab::Geo.notify_wiki_update(@project) if Gitlab::Geo.primary?
      redirect_to(
        namespace_project_wiki_path(@project.namespace, @project, @page),
        notice: 'Wiki was successfully updated.'
      )
    else
      render 'edit'
    end
  end

  def create
    @page = WikiPages::CreateService.new(@project, current_user, wiki_params).execute

    if @page.persisted?
      # Triggers repository update on secondary nodes when Geo is enabled
      Gitlab::Geo.notify_wiki_update(@project) if Gitlab::Geo.primary?
      redirect_to(
        namespace_project_wiki_path(@project.namespace, @project, @page),
        notice: 'Wiki was successfully updated.'
      )
    else
      render action: "edit"
    end
  end

  def history
    @page = @project_wiki.find_page(params[:id])

    unless @page
      redirect_to(
        namespace_project_wiki_path(@project.namespace, @project, :home),
        notice: "Page not found"
      )
    end
  end

  def destroy
    @page = @project_wiki.find_page(params[:id])
    if @page
      @page.delete

      # Triggers repository update on secondary nodes when Geo is enabled
      Gitlab::Geo.notify_wiki_update(@project) if Gitlab::Geo.primary?
    end
    
    redirect_to(
      namespace_project_wiki_path(@project.namespace, @project, :home),
      notice: "Page was successfully deleted"
    )
  end

  def markdown_preview
    text = params[:text]

    ext = Gitlab::ReferenceExtractor.new(@project, current_user)
    ext.analyze(text, author: current_user)

    render json: {
      body: view_context.markdown(text, pipeline: :wiki, project_wiki: @project_wiki, page_slug: params[:id]),
      references: {
        users: ext.users.map(&:username)
      }
    }
  end

  def git_access
  end

  private

  def load_project_wiki
    @project_wiki = ProjectWiki.new(@project, current_user)

    # Call #wiki to make sure the Wiki Repo is initialized
    @project_wiki.wiki
  rescue ProjectWiki::CouldNotCreateWikiError
    flash[:notice] = "Could not create Wiki Repository at this time. Please try again later."
    redirect_to project_path(@project)
    return false
  end

  def wiki_params
    params[:wiki].slice(:title, :content, :format, :message)
  end
end
