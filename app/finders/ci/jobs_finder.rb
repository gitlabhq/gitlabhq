# frozen_string_literal: true

module Ci
  class JobsFinder
    include Gitlab::Allowable

    def initialize(current_user:, pipeline: nil, project: nil, params: {}, type: ::Ci::Build)
      @pipeline = pipeline
      @current_user = current_user
      @project = project
      @params = params
      @type = type
      raise ArgumentError 'type must be a subclass of Ci::Processable' unless type < ::Ci::Processable
    end

    def execute
      builds = init_collection.order_id_desc
      filter_by_scope(builds)
    rescue Gitlab::Access::AccessDeniedError
      type.none
    end

    private

    attr_reader :current_user, :pipeline, :project, :params, :type

    def init_collection
      pipeline_jobs || project_jobs || all_jobs
    end

    def all_jobs
      raise Gitlab::Access::AccessDeniedError unless current_user&.admin?

      type.all
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

    def filter_by_statuses!(builds)
      unknown_statuses = params[:scope] - ::CommitStatus::AVAILABLE_STATUSES
      raise ArgumentError, 'Scope contains invalid value(s)' unless unknown_statuses.empty?

      builds.where(status: params[:scope]) # rubocop: disable CodeReuse/ActiveRecord
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
