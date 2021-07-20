# frozen_string_literal: true

module Ci
  # Takes in input a Ci::Bridge job and creates a downstream pipeline
  # (either multi-project or child pipeline) according to the Ci::Bridge
  # specifications.
  class CreateDownstreamPipelineService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    DuplicateDownstreamPipelineError = Class.new(StandardError)

    MAX_DESCENDANTS_DEPTH = 2

    def execute(bridge)
      @bridge = bridge

      if bridge.has_downstream_pipeline?
        Gitlab::ErrorTracking.track_exception(
          DuplicateDownstreamPipelineError.new,
          bridge_id: @bridge.id, project_id: @bridge.project_id
        )

        return error('Already has a downstream pipeline')
      end

      pipeline_params = @bridge.downstream_pipeline_params
      target_ref = pipeline_params.dig(:target_revision, :ref)

      return error('Pre-conditions not met') unless ensure_preconditions!(target_ref)

      service = ::Ci::CreatePipelineService.new(
        pipeline_params.fetch(:project),
        current_user,
        pipeline_params.fetch(:target_revision))

      downstream_pipeline = service
        .execute(pipeline_params.fetch(:source), **pipeline_params[:execute_params])
        .payload

      downstream_pipeline.tap do |pipeline|
        update_bridge_status!(@bridge, pipeline)
      end
    end

    private

    def update_bridge_status!(bridge, pipeline)
      Gitlab::OptimisticLocking.retry_lock(bridge, name: 'create_downstream_pipeline_update_bridge_status') do |subject|
        if pipeline.created_successfully?
          # If bridge uses `strategy:depend` we leave it running
          # and update the status when the downstream pipeline completes.
          subject.success! unless subject.dependent?
        else
          subject.options[:downstream_errors] = pipeline.errors.full_messages
          subject.drop!(:downstream_pipeline_creation_failed)
        end
      end
    rescue StateMachines::InvalidTransition => e
      Gitlab::ErrorTracking.track_exception(
        Ci::Bridge::InvalidTransitionError.new(e.message),
        bridge_id: bridge.id,
        downstream_pipeline_id: pipeline.id)
    end

    def ensure_preconditions!(target_ref)
      unless downstream_project_accessible?
        @bridge.drop!(:downstream_bridge_project_not_found)
        return false
      end

      # TODO: Remove this condition if favour of model validation
      # https://gitlab.com/gitlab-org/gitlab/issues/38338
      if downstream_project == project && !@bridge.triggers_child_pipeline?
        @bridge.drop!(:invalid_bridge_trigger)
        return false
      end

      # TODO: Remove this condition if favour of model validation
      # https://gitlab.com/gitlab-org/gitlab/issues/38338
      if has_max_descendants_depth?
        @bridge.drop!(:reached_max_descendant_pipelines_depth)
        return false
      end

      unless can_create_downstream_pipeline?(target_ref)
        @bridge.drop!(:insufficient_bridge_permissions)
        return false
      end

      if has_cyclic_dependency?
        @bridge.drop!(:pipeline_loop_detected)

        return false
      end

      true
    end

    def downstream_project_accessible?
      downstream_project.present? &&
        can?(current_user, :read_project, downstream_project)
    end

    def can_create_downstream_pipeline?(target_ref)
      can?(current_user, :update_pipeline, project) &&
        can?(current_user, :create_pipeline, downstream_project) &&
          can_update_branch?(target_ref)
    end

    def can_update_branch?(target_ref)
      ::Gitlab::UserAccess.new(current_user, container: downstream_project).can_update_branch?(target_ref)
    end

    def downstream_project
      strong_memoize(:downstream_project) do
        @bridge.downstream_project
      end
    end

    def has_cyclic_dependency?
      return false if @bridge.triggers_child_pipeline?

      if Feature.enabled?(:ci_drop_cyclical_triggered_pipelines, @bridge.project, default_enabled: :yaml)
        pipeline_checksums = @bridge.pipeline.self_and_upstreams.filter_map do |pipeline|
          config_checksum(pipeline) unless pipeline.child?
        end

        pipeline_checksums.uniq.length != pipeline_checksums.length
      end
    end

    def has_max_descendants_depth?
      return false unless @bridge.triggers_child_pipeline?

      ancestors_of_new_child = @bridge.pipeline.self_and_ancestors
      ancestors_of_new_child.count > MAX_DESCENDANTS_DEPTH
    end

    def config_checksum(pipeline)
      [pipeline.project_id, pipeline.ref].hash
    end
  end
end
