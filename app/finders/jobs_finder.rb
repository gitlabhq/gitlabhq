# frozen_string_literal: true

class JobsFinder
  include Gitlab::Allowable

  def initialize(current_user:, project: nil, params: {})
    @current_user = current_user
    @project = project
    @params = params
  end

  def execute
    builds = init_collection.order_id_desc
    filter_by_scope(builds)
  rescue Gitlab::Access::AccessDeniedError
    Ci::Build.none
  end

  private

  attr_reader :current_user, :project, :params

  def init_collection
    project ? project_builds : all_builds
  end

  def all_builds
    raise Gitlab::Access::AccessDeniedError unless current_user&.admin?

    Ci::Build.all
  end

  def project_builds
    raise Gitlab::Access::AccessDeniedError unless can?(current_user, :read_build, project)

    project.builds.relevant
  end

  def filter_by_scope(builds)
    case params[:scope]
    when 'pending'
      builds.pending.reverse_order
    when 'running'
      builds.running.reverse_order
    when 'finished'
      builds.finished
    else
      builds
    end
  end
end
