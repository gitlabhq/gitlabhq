class Projects::CiCommitsController < Projects::ApplicationController
  before_action :ci_commit, except: [:index]
  before_action :authorize_read_build!
  layout 'project'

  def index
    @scope = params[:scope]
    @all_commits = project.ci_commits
    @commits = @all_commits.order(id: :desc)
    @commits =
      case @scope
      when 'latest'
        @commits
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

  def show
    @commit = @ci_commit.commit
    @builds = @ci_commit.builds
    @statuses = @ci_commit.statuses

    respond_to do |format|
      format.html
    end
  end

  private

  def ci_commit
    @ci_commit ||= project.ci_commits.find_by!(id: params[:id])
  end
end
