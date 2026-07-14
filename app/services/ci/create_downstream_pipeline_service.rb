# frozen_string_literal: true

module Ci
  # Takes in input a Ci::Bridge job and creates a downstream pipeline
  # (either multi-project or child pipeline) according to the Ci::Bridge
  # specifications.
  class CreateDownstreamPipelineService < ::BaseService
    include Gitlab::Utils::StrongMemoize
    include Ci::DownstreamPipelineHelpers

    MAX_NESTED_CHILDREN = 2

    def execute(bridge)
      @bridge = bridge

      return ServiceResponse.error(message: 'Can not run a failed bridge') if @bridge.failed?

      return ServiceResponse.error(message: 'Already has a downstream pipeline') if @bridge.has_downstream_pipeline?

      pipeline_params = @bridge.downstream_pipeline_params
      target_ref = pipeline_params.dig(:target_revision, :ref)

      return ServiceResponse.error(message: 'Pre-conditions not met') unless ensure_preconditions!(target_ref)

      # Allow retrying if the bridge is already running but has no downstream pipeline.
      # This handles the case where a previous worker was terminated mid-execution.
      unless @bridge.running? || @bridge.run
        return ServiceResponse.error(message: "Cannot run the bridge, status: #{@bridge.status}")
      end

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
      if pipeline.created_successfully?
        Gitlab::OptimisticLocking.retry_lock(bridge,
          name: 'create_downstream_pipeline_update_bridge_status_success') do |subject|
          subject.success! unless subject.has_strategy?
          ServiceResponse.success(payload: pipeline)
        end
      else
        drop_bridge!(bridge, pipeline)
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

    def drop_bridge!(bridge, pipeline)
      messages = pipeline.errors.full_messages

      Gitlab::OptimisticLocking.retry_lock(bridge,
        name: 'create_downstream_pipeline_update_bridge_status_failure') do |subject|
        subject.drop!(:downstream_pipeline_creation_failed)
      end

      create_downstream_error_messages(bridge, messages)

      ServiceResponse.error(payload: pipeline, message: messages)
    end

    def create_downstream_error_messages(bridge, messages)
      messages.each do |message|
        attributes = { content: message, project_id: bridge.project_id }
        bridge.job_messages.error.create!(attributes)
      end
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
        downstream_project.organization_id == project.organization_id &&
        can?(current_user, :read_project, downstream_project)
    end

    def can_create_downstream_pipeline?(target_ref)
      can?(current_user, :update_pipeline, project) &&
        can?(current_user, :create_pipeline, downstream_project) &&
        can_write_ref?(target_ref)
    end

    def can_write_ref?(target_ref)
      access = ::Gitlab::UserAccess.new(current_user, container: downstream_project)

      if Gitlab::Git.branch_ref?(target_ref)
        # Use can_run_pipeline_on_branch? instead of can_update_branch? to preserve
        # the EE override that allows security policy bots (Guests) to create pipelines
        # via the :create_bot_pipeline permission.
        access.can_run_pipeline_on_branch?(Gitlab::Git.ref_name(target_ref))
      elsif Gitlab::Git.tag_ref?(target_ref)
        access.can_create_tag?(Gitlab::Git.ref_name(target_ref))
      elsif @bridge.triggers_child_pipeline? && MergeRequest.merge_request_ref?(target_ref)
        # For MR refs, check permissions based on fork vs same-project
        # See: lib/gitlab/ci/pipeline/chain/validate/abilities.rb
        merge_request = @bridge.pipeline.merge_request
        if merge_request.nil?
          false
        elsif merge_request.for_fork?
          true
        else # => merge_request.for_same_project? == true
          access.can_run_pipeline_on_branch?(merge_request.source_branch)
        end
      else
        # Treat any other ref pattern as branch -- Ci::CreatePipelineService will check this later anyway
        access.can_run_pipeline_on_branch?(target_ref)
      end
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
