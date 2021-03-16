# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class AtomicProcessingService
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      attr_reader :pipeline

      DEFAULT_LEASE_TIMEOUT = 1.minute
      BATCH_SIZE = 20

      def initialize(pipeline)
        @pipeline = pipeline
        @collection = AtomicProcessingService::StatusCollection.new(pipeline)
      end

      def execute
        return unless pipeline.needs_processing?

        success = try_obtain_lease { process! }

        # re-schedule if we need further processing
        if success && pipeline.needs_processing?
          PipelineProcessWorker.perform_async(pipeline.id)
        end

        success
      end

      private

      def process!
        update_stages!
        update_pipeline!
        update_statuses_processed!

        true
      end

      def update_stages!
        pipeline.stages.ordered.each(&method(:update_stage!))
      end

      def update_stage!(stage)
        # Update processables for a given stage in bulk/slices
        ids = @collection.created_processable_ids_for_stage_position(stage.position)
        ids.in_groups_of(BATCH_SIZE, false, &method(:update_processables!))

        status = @collection.status_for_stage_position(stage.position)
        stage.set_status(status)
      end

      def update_processables!(ids)
        created_processables = pipeline.processables.id_in(ids)
          .with_project_preload
          .created
          .latest
          .ordered_by_stage
          .select_with_aggregated_needs(project)

        created_processables.each(&method(:update_processable!))
      end

      def update_pipeline!
        pipeline.set_status(@collection.status_of_all)
      end

      def update_statuses_processed!
        processing = @collection.processing_processables
        processing.each_slice(BATCH_SIZE) do |slice|
          pipeline.statuses.match_id_and_lock_version(slice)
            .update_as_processed!
        end
      end

      def update_processable!(processable)
        status = processable_status(processable)
        return unless Ci::HasStatus::COMPLETED_STATUSES.include?(status)

        # transition status if possible
        Gitlab::OptimisticLocking.retry_lock(processable, name: 'atomic_processing_update_processable') do |subject|
          Ci::ProcessBuildService.new(project, subject.user)
            .execute(subject, status)

          # update internal representation of status
          # to make the status change of processable
          # to be taken into account during further processing
          @collection.set_processable_status(
            processable.id, processable.status, processable.lock_version)
        end
      end

      def processable_status(processable)
        if processable.scheduling_type_dag?
          # Processable uses DAG, get status of all dependent needs
          @collection.status_for_names(processable.aggregated_needs_names.to_a, dag: true)
        else
          # Processable uses Stages, get status of prior stage
          @collection.status_for_prior_stage_position(processable.stage_idx.to_i)
        end
      end

      def project
        pipeline.project
      end

      def lease_key
        "#{super}::pipeline_id:#{pipeline.id}"
      end

      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end
