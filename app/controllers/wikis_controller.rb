class WikisController < ApplicationController
  before_filter :project
  layout "project"
  respond_to :html
  
  def show
    @wiki = @project.wikis.find_by_slug(params[:id])
    respond_with(@wiki)
  end

  def new
    @wiki = Wiki.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @wiki }
    end
  end

  def edit
    @wiki = Wiki.find(params[:id])
  end

  def create
    @wiki = Wiki.new(params[:wiki])

    respond_to do |format|
      if @wiki.save
        format.html { redirect_to @wiki, notice: 'Wiki was successfully created.' }
        format.json { render json: @wiki, status: :created, location: @wiki }
      else
        format.html { render action: "new" }
        format.json { render json: @wiki.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @wiki = Wiki.find(params[:id])

    respond_to do |format|
      if @wiki.update_attributes(params[:wiki])
        format.html { redirect_to @wiki, notice: 'Wiki was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @wiki.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @wiki = Wiki.find(params[:id])
    @wiki.destroy

    respond_to do |format|
      format.html { redirect_to wikis_url }
      format.json { head :no_content }
    end
  end
end
