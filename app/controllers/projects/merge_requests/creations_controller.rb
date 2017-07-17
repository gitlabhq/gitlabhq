class Projects::MergeRequests::CreationsController < Projects::MergeRequests::ApplicationController
  include DiffForPath
  include DiffHelper

  prepend ::EE::Projects::MergeRequests::CreationsController

  skip_before_action :merge_request
  skip_before_action :ensure_ref_fetched
  before_action :authorize_create_merge_request!
  before_action :apply_diff_view_cookie!, only: [:diffs, :diff_for_path]
  before_action :build_merge_request, except: [:create]

  def new
    define_new_vars
  end

  def create
    @target_branches ||= []
    @merge_request = ::MergeRequests::CreateService.new(project, current_user, merge_request_params).execute

    if @merge_request.valid?
      redirect_to(merge_request_path(@merge_request))
    else
      @source_project = @merge_request.source_project
      @target_project = @merge_request.target_project

      define_new_vars
      render action: "new"
    end
  end

  def pipelines
    @pipelines = @merge_request.all_pipelines

    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render json: {
      pipelines: PipelineSerializer
      .new(project: @project, current_user: @current_user)
      .represent(@pipelines)
    }
  end

  def diffs
    @diffs = if @merge_request.can_be_created
               @merge_request.diffs(diff_options)
             else
               []
             end
    @diff_notes_disabled = true

    @environment = @merge_request.environments_for(current_user).last

    render json: { html: view_to_html_string('projects/merge_requests/creations/_diffs', diffs: @diffs, environment: @environment) }
  end

  def diff_for_path
    @diffs = @merge_request.diffs(diff_options)
    @diff_notes_disabled = true

    render_diff_for_path(@diffs)
  end

  def branch_from
    # This is always source
    @source_project = @merge_request.nil? ? @project : @merge_request.source_project

    if params[:ref].present?
      @ref = params[:ref]
      @commit = @repository.commit("refs/heads/#{@ref}")
    end

    render layout: false
  end

  def branch_to
    @target_project = selected_target_project

    if params[:ref].present?
      @ref = params[:ref]
      @commit = @target_project.commit("refs/heads/#{@ref}")
    end

    render layout: false
  end

  def update_branches
    @target_project = selected_target_project
    @target_branches = @target_project.repository.branch_names

    render layout: false
  end

  private

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)
    @merge_request = ::MergeRequests::BuildService.new(project, current_user, merge_request_params.merge(diff_options: diff_options)).execute
  end

  def define_new_vars
    @noteable = @merge_request

    @target_branches = if @merge_request.target_project
                         @merge_request.target_project.repository.branch_names
                       else
                         []
                       end

    @target_project = @merge_request.target_project
    @source_project = @merge_request.source_project
    @commits = @merge_request.commits
    @commit = @merge_request.diff_head_commit

    @note_counts = Note.where(commit_id: @commits.map(&:id))
      .group(:commit_id).count

    @labels = LabelsFinder.new(current_user, project_id: @project.id).execute

    set_pipeline_variables
  end

  def selected_target_project
    if @project.id.to_s == params[:target_project_id] || @project.forked_project_link.nil?
      @project
    else
      @project.forked_project_link.forked_from_project
    end
  end
end
