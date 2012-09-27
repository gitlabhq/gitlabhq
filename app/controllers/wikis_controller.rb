class WikisController < ProjectResourceController
  before_filter :authorize_read_wiki!
  before_filter :authorize_write_wiki!, only: [:edit, :create, :history]
  before_filter :authorize_admin_wiki!, only: :destroy
  
  def pages
    @wikis = @project.wikis.group(:slug).order("created_at")
  end

  def show
    if params[:old_page_id]
      @wiki = @project.wikis.find(params[:old_page_id])
    else
      @wiki = @project.wikis.where(slug: params[:id]).order("created_at").last
    end

    @note = @project.notes.new(noteable: @wiki)

    if @wiki
      render 'show'
    else
      if can?(current_user, :write_wiki, @project)
        @wiki = @project.wikis.new(slug: params[:id])
        render 'edit'
      else
        render 'empty'
      end
    end
  end

  def edit
    @wiki = @project.wikis.where(slug: params[:id]).order("created_at").last
    @wiki = Wiki.regenerate_from @wiki
  end

  def create
    @wiki = @project.wikis.new(params[:wiki])
    @wiki.user = current_user

    respond_to do |format|
      if @wiki.save
        format.html { redirect_to [@project, @wiki], notice: 'Wiki was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def history
    @wikis = @project.wikis.where(slug: params[:id]).order("created_at")
  end
  
  def destroy
    @wikis = @project.wikis.where(slug: params[:id]).delete_all

    respond_to do |format|
      format.html { redirect_to project_wiki_path(@project, :index), notice: "Page was successfully deleted" }
    end
  end
end
