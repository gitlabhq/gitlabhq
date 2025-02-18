# frozen_string_literal: true

module Ci
  class JobsFinder
    include Gitlab::Allowable

    def initialize(current_user:, pipeline: nil, project: nil, runner: nil, params: {}, type: ::Ci::Build)
      @current_user = current_user
      @pipeline = pipeline
      @project = project
      @runner = runner
      @params = params
      @type = type
      raise ArgumentError 'type must be a subclass of Ci::Processable' unless type < ::Ci::Processable
    end

    def execute
      # params[:skip_ordering] needed when using in conjunction with Ci::BuildSourceFinder
      # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170899
      builds = params[:skip_ordering] ? init_collection : init_collection.order_id_desc

      filter_builds(builds)
    rescue Gitlab::Access::AccessDeniedError
      type.none
    end

    private

    attr_reader :current_user, :pipeline, :project, :runner, :params, :type

    def init_collection
      pipeline_jobs || project_jobs || runner_jobs || all_jobs
    end

    def all_jobs
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :read_admin_cicd)

      type.all
    end

    def runner_jobs
      return unless runner
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :read_builds, runner)

      jobs_by_type(runner, type).relevant
    end

    def project_jobs
      return unless project
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :read_build, project)

      jobs_by_type(project, type).relevant
    end

    def pipeline_jobs
      return unless pipeline
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :read_build, pipeline)

      jobs_scope = jobs_by_type(pipeline, type)
      params[:include_retried] ? jobs_scope : jobs_scope.latest
    end

    # Overriden in EE
    def filter_builds(builds)
      builds = filter_by_with_artifacts(builds)
      builds = filter_by_runner_types(builds)
      filter_by_scope(builds)
    end

    def filter_by_scope(builds)
      return filter_by_statuses!(builds) if params[:scope].is_a?(Array)

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

    def filter_by_runner_types(builds)
      return builds unless use_runner_type_filter?

      builds.with_runner_type(params[:runner_type])
    end

    # Overriden in EE
    def use_runner_type_filter?
      params[:runner_type].present? && Feature.enabled?(:admin_jobs_filter_runner_type, project, type: :ops)
    end

    def filter_by_with_artifacts(builds)
      return builds.with_any_artifacts if params[:with_artifacts]

      builds
    end

    def filter_by_statuses!(builds)
      unknown_statuses = params[:scope] - ::CommitStatus::AVAILABLE_STATUSES
      raise ArgumentError, 'Scope contains invalid value(s)' unless unknown_statuses.empty?

      builds.with_statuses(params[:scope])
    end

    def jobs_by_type(relation, type)
      case type.name
      when ::Ci::Build.name
        relation.builds
      when ::Ci::Bridge.name
        relation.bridges
      else
        raise ArgumentError, "finder does not support #{type} type"
      end
    end
  end
end

Ci::JobsFinder.prepend_mod
