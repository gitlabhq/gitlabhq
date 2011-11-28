class MergeRequestsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project
  before_filter :merge_request, :only => [:edit, :update, :destroy, :show]
  layout "project"

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_project!
  before_filter :authorize_write_project!, :only => [:new, :create, :edit, :update]

  def index
    @merge_requests = @project.merge_requests.all
  end

  def show
    unless @project.repo.heads.map(&:name).include?(@merge_request.target_branch) && 
      @project.repo.heads.map(&:name).include?(@merge_request.source_branch)
      head(404)and return 
    end

    @commits = @project.repo.commits_between(@merge_request.target_branch, @merge_request.source_branch).map {|c| Commit.new(c)}
  end

  def new
    @merge_request = @project.merge_requests.new
  end

  def edit
  end

  def create
    @merge_request = @project.merge_requests.new(params[:merge_request])
    @merge_request.author = current_user

    respond_to do |format|
      if @merge_request.save
        format.html { redirect_to [@project, @merge_request], notice: 'Merge request was successfully created.' }
        format.json { render json: @merge_request, status: :created, location: @merge_request }
      else
        format.html { render action: "new" }
        format.json { render json: @merge_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @merge_request.update_attributes(params[:merge_request])
        format.html { redirect_to [@project, @merge_request], notice: 'Merge request was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @merge_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @merge_request.destroy

    respond_to do |format|
      format.html { redirect_to project_merge_requests_url(@project) }
      format.json { head :ok }
    end
  end

  protected

  def merge_request
    @merge_request ||= @project.merge_requests.find(params[:id])
  end
end
