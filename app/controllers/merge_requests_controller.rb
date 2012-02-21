class MergeRequestsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project
  before_filter :module_enabled
  before_filter :merge_request, :only => [:edit, :update, :destroy, :show, :commits, :diffs]
  layout "project"

  # Authorize
  before_filter :add_project_abilities

  # Allow read any merge_request
  before_filter :authorize_read_merge_request!

  # Allow write(create) merge_request
  before_filter :authorize_write_merge_request!, :only => [:new, :create]

  # Allow modify merge_request
  before_filter :authorize_modify_merge_request!, :only => [:close, :edit, :update, :sort]

  # Allow destroy merge_request
  before_filter :authorize_admin_merge_request!, :only => [:destroy]

  def index
    @merge_requests = @project.merge_requests

    @merge_requests = case params[:f].to_i
                      when 1 then @merge_requests
                      when 2 then @merge_requests.closed
                      when 2 then @merge_requests.opened.assigned(current_user)
                      else @merge_requests.opened
                      end

    @merge_requests = @merge_requests.includes(:author, :project)
  end

  def show
    unless @project.repo.heads.map(&:name).include?(@merge_request.target_branch) && 
      @project.repo.heads.map(&:name).include?(@merge_request.source_branch)
      head(404)and return 
    end

    @notes = @merge_request.notes.inc_author.order("created_at DESC").limit(20)
    @note = @project.notes.new(:noteable => @merge_request)

    @commits = @project.repo.
      commits_between(@merge_request.target_branch, @merge_request.source_branch).
      map {|c| Commit.new(c)}.
      sort_by(&:created_at).
      reverse

    render_full_content

    respond_to do |format|
      format.html
      format.js { respond_with_notes }
    end
  end

  def diffs
    @diffs = @merge_request.diffs
    @commit = @merge_request.last_commit
    @line_notes = []
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

  def authorize_modify_merge_request!
    return render_404 unless can?(current_user, :modify_merge_request, @merge_request)
  end

  def authorize_admin_merge_request!
    return render_404 unless can?(current_user, :admin_merge_request, @merge_request)
  end

  def module_enabled
    return render_404 unless @project.merge_requests_enabled
  end
end
