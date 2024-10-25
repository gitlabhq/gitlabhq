# frozen_string_literal: true

module Ci
  # Takes in input a Ci::Bridge job and creates a downstream pipeline
  # (either multi-project or child pipeline) according to the Ci::Bridge
  # specifications.
  class CreateDownstreamPipelineService < ::BaseService
    include Gitlab::Utils::StrongMemoize
    include Ci::DownstreamPipelineHelpers

    DuplicateDownstreamPipelineError = Class.new(StandardError)

    MAX_NESTED_CHILDREN = 2

    def execute(bridge)
      @bridge = bridge

      if @bridge.has_downstream_pipeline?
        Gitlab::ErrorTracking.track_exception(
          DuplicateDownstreamPipelineError.new,
          bridge_id: @bridge.id, project_id: @bridge.project_id
        )

        return ServiceResponse.error(message: 'Already has a downstream pipeline')
      end

      pipeline_params = @bridge.downstream_pipeline_params
      target_ref = pipeline_params.dig(:target_revision, :ref)

      return ServiceResponse.error(message: 'Pre-conditions not met') unless ensure_preconditions!(target_ref)

      return ServiceResponse.error(message: 'Can not run the bridge') unless @bridge.run

      service = ::Ci::CreatePipelineService.new(
        pipeline_params.fetch(:project),
        current_user,
        pipeline_params.fetch(:target_revision))

      downstream_pipeline = service
        .execute(pipeline_params.fetch(:source), **pipeline_params[:execute_params])
        .payload

      log_downstream_pipeline_creation(downstream_pipeline)
      log_audit_event(downstream_pipeline)
      update_bridge_status!(@bridge, downstream_pipeline)
    rescue StandardError => e
      @bridge.reset.drop!(:data_integrity_failure)
      raise e
    end

    def log_audit_event(downstream_pipeline)
      # defined in EE
    end

    private

    def update_bridge_status!(bridge, pipeline)
      Gitlab::OptimisticLocking.retry_lock(bridge, name: 'create_downstream_pipeline_update_bridge_status') do |subject|
        if pipeline.created_successfully?
          # If bridge uses `strategy:depend` we leave it running
          # and update the status when the downstream pipeline completes.
          subject.success! unless subject.dependent?
          ServiceResponse.success(payload: pipeline)
        else
          message = pipeline.errors.full_messages
          subject.options[:downstream_errors] = message
          subject.drop!(:downstream_pipeline_creation_failed)
          ServiceResponse.error(payload: pipeline, message: message)
        end
      end
    rescue StateMachines::InvalidTransition => e
      error = Ci::Bridge::InvalidTransitionError.new(e.message)
      error.set_backtrace(caller)
      Gitlab::ErrorTracking.track_exception(
        error,
        bridge_id: bridge.id,
        downstream_pipeline_id: pipeline.id)
      ServiceResponse.error(payload: pipeline, message: e.message)
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
      # only applies to parent-child pipelines not multi-project
      if has_max_nested_children?
        @bridge.drop!(:reached_max_descendant_pipelines_depth)
        return false
      end

      if pipeline_tree_too_large?
        @bridge.drop!(:reached_max_pipeline_hierarchy_size)
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

      pipeline_checksums = @bridge.pipeline.self_and_upstreams.filter_map do |pipeline|
        config_checksum(pipeline) unless pipeline.child?
      end

      # To avoid false positives we allow 1 cycle in the ancestry and
      # fail when 2 cycles are detected: A -> B -> A -> B -> A
      pipeline_checksums.tally.any? { |_checksum, occurrences| occurrences > 2 }
    end

    def has_max_nested_children?
      return false unless @bridge.triggers_child_pipeline?

      # only applies to parent-child pipelines not multi-project
      ancestors_of_new_child = @bridge.pipeline.self_and_project_ancestors
      ancestors_of_new_child.count > MAX_NESTED_CHILDREN
    end

    def pipeline_tree_too_large?
      return false unless @bridge.triggers_downstream_pipeline?

      # Applies to the entire pipeline tree across all projects
      # A pipeline tree can be shared between multiple namespaces (customers), the limit that is used here
      # is the limit of the namespace that has added a downstream pipeline to a pipeline tree.
      @bridge.project.actual_limits.exceeded?(:pipeline_hierarchy_size, complete_hierarchy_count)
    end

    def complete_hierarchy_count
      @bridge.pipeline.complete_hierarchy_count
    end

    def config_checksum(pipeline)
      [pipeline.project_id, pipeline.ref, pipeline.source].hash
    end
  end
end

Ci::CreateDownstreamPipelineService.prepend_mod_with('Ci::CreateDownstreamPipelineService')
