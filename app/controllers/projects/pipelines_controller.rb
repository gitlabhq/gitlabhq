class Projects::PipelinesController < Projects::ApplicationController
  before_action :pipeline, except: [:index, :new, :create]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  layout 'project'

  def index
    @scope = params[:scope]
    @all_pipelines = project.ci_commits
    @pipelines = @all_pipelines.order(id: :desc)
    @pipelines =
      case @scope
      when 'running'
        @pipelines.running_or_pending
      when 'branches'
        @branches = project.repository.branches.map(&:name)
        @branches_ids = @all_pipelines.where(ref: @branches).group(:ref).select('max(id)')
        @pipelines.where(id: @branches_ids)
      when 'tags'
        @tags = project.repository.tags.map(&:name)
        @tags_ids = @all_pipelines.where(ref: @tags).group(:ref).select('max(id)')
        @pipelines.where(id: @tags_ids)
      else
        @pipelines
      end
    @pipelines = @pipelines.page(params[:page]).per(30)
  end

  def new
  end

  def create
    ref_names = project.repository.ref_names
    unless ref_names.include?(params[:ref])
      @error = 'Reference not found'
      render action: 'new'
      return
    end

    commit = project.commit(params[:ref])
    unless commit
      @error = 'Commit not found'
      render action: 'new'
      return
    end

    pipeline = project.ci_commits.new(sha: commit.id, ref: params[:ref], before_sha: Gitlab::Git::BLANK_SHA)

    # Skip creating ci_commit when no gitlab-ci.yml is found
    unless pipeline.config_processor
      @error = pipeline.yaml_errors || 'Missing .gitlab-ci.yml file'
      render action: 'new'
      return
    end

    Ci::Commit.transaction do
      commit.save!
      commit.create_builds(current_user)
    end

    redirect_to builds_namespace_project_commit_path(project.namespace, project, commit.id)
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def retry
    pipeline.builds.latest.failed.select(&:retryable?).each(&:retry)

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  def cancel
    pipeline.builds.running_or_pending.each(&:cancel)

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  private

  def pipeline
    @pipeline ||= project.ci_commits.find_by!(id: params[:id])
  end
end
