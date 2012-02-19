class WikisController < ApplicationController
  before_filter :project
  before_filter :add_project_abilities
  layout "project"
  
  def show
    @wiki = @project.wikis.where(:slug => params[:id]).order("created_at").last
    respond_to do |format|
      if @wiki
        format.html
      else
        @wiki = @project.wikis.new(:slug => params[:id])
        format.html { render "edit" }
      end
    end
  end

  def edit
    @wiki = @project.wikis.where(:slug => params[:id]).order("created_at").last
    @wiki = Wiki.regenerate_from @wiki
  end

  def create
    @wiki = @project.wikis.new(params[:wiki])

    respond_to do |format|
      if @wiki.save
        format.html { redirect_to [@project, @wiki], notice: 'Wiki was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end
  
  def destroy
    @wiki = @project.wikis.find(params[:id])
    @wiki.destroy

    respond_to do |format|
      format.html { redirect_to wikis_url }
    end
  end
end
