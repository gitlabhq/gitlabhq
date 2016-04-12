class Projects::PipelineController < Projects::ApplicationController
  before_action :ci_commit, except: [:index, :new, :create]
  before_action :authorize_read_pipeline!
  before_action :authorize_create_pipeline!, only: [:new, :create]
  before_action :authorize_update_pipeline!, only: [:retry, :cancel]
  layout 'project'

  def index
    @scope = params[:scope]
    @all_commits = project.ci_commits
    @commits = @all_commits.order(id: :desc)
    @commits =
      case @scope
      when 'latest'
        @commits
      when 'running'
        @commits.running_or_pending
      when 'branches'
        refs = project.repository.branches.map(&:name)
        ids = @all_commits.where(ref: refs).group(:ref).select('max(id)')
        @commits.where(id: ids)
      when 'tags'
        refs = project.repository.tags.map(&:name)
        ids = @all_commits.where(ref: refs).group(:ref).select('max(id)')
        @commits.where(id: ids)
      else
        @commits
      end
    @commits = @commits.page(params[:page]).per(30)
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

    ci_commit = project.ci_commit(commit.id, params[:ref])
    if ci_commit
      @error = 'Pipeline already created'
      render action: 'new'
      return
    end

    # Skip creating ci_commit when no gitlab-ci.yml is found
    commit = project.ci_commits.new(sha: commit.id, ref: params[:ref], before_sha: Gitlab::Git::BLANK_SHA)
    unless commit.config_processor
      @error = commit.yaml_errors || 'Missing .gitlab-ci.yml file'
      render action: 'new'
      return
    end

    Ci::Commit.transaction do
      commit.save!
      commit.create_builds(params[:ref], false, current_user)
    end

    redirect_to builds_namespace_project_commit_path(project.namespace, project, commit.id)
  end

  def show
    @commit = @ci_commit.commit
    @builds = @ci_commit.builds
    @statuses = @ci_commit.statuses

    respond_to do |format|
      format.html
    end
  end

  def retry
    ci_commit.builds.latest.failed.select(&:retryable?).each(&:retry)

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  def cancel
    ci_commit.builds.running_or_pending.each(&:cancel)

    redirect_back_or_default default: namespace_project_pipelines_path(project.namespace, project)
  end

  def retry_builds
  end
  private

  def ci_commit
    @ci_commit ||= project.ci_commits.find_by!(id: params[:id])
  end
end
