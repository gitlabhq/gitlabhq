# frozen_string_literal: true

module Ci
  module PipelineCreation
    class CancelRedundantPipelinesService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 25
      PAGE_SIZE = 500
      MAX_CANCELLATIONS_PER_PIPELINE = 3000
      ID_BATCH_SIZE = 1000

      def initialize(pipeline)
        @pipeline = pipeline
        @project = @pipeline.project

        @skipped_for_old_age      = 0
        @conservatively_cancelled = 0
        @aggressively_cancelled   = 0
        @configured_to_not_cancel = 0
      end

      def execute
        return if service_disabled?
        return if pipeline.parent_pipeline? # skip if child pipeline
        return unless project.auto_cancel_pending_pipelines?

        auto_cancel_all_pipelines_with_cancelable_statuses
      end

      private

      attr_reader :pipeline, :project

      def cancelable_status_pipeline_ids
        project.all_pipelines
          .for_ref(pipeline.ref)
          .id_not_in(pipeline.id)
          .with_status(Ci::Pipeline::CANCELABLE_STATUSES)
          .order_id_desc # Query the most recently created cancellable Pipelines
          .limit(MAX_CANCELLATIONS_PER_PIPELINE)
          .pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
          .reverse # Once we have the most recent Pipelines, cancel oldest & upstreams first
      end
      strong_memoize_attr :cancelable_status_pipeline_ids

      def ref_head_sha
        project.commit(pipeline.ref).try(:id)
      end
      strong_memoize_attr :ref_head_sha

      def auto_cancel_all_pipelines_with_cancelable_statuses
        cancelable_status_pipeline_ids.each_slice(ID_BATCH_SIZE) do |ids_batch|
          Ci::Pipeline.id_in(ids_batch).order_id_asc.each do |cancelable|
            case cancelable.source.to_sym
            when *Enums::Ci::Pipeline.ci_sources.keys
              # Newer pipelines are not cancelable. This doesn't normally occur
              # but needs to be handled in asynchronous execution.
              next if cancelable.created_at >= pipeline.created_at
            when :parent_pipeline
              # Child pipelines are cancelable based on the root parent age
              next if cancelable.root_ancestor.created_at >= pipeline.created_at
            else
              # Skip other pipeline sources
              next
            end

            next if cancelable.sha == pipeline.sha
            next if cancelable.sha == ref_head_sha

            if cancelable.created_at < pipelines_created_after
              @skipped_for_old_age += 1

              next
            end

            # Cancel method based on configured strategy
            configured_cancellation_for(cancelable)
          end
        end

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Canceling redundant pipelines",
          cancellable_count: cancelable_status_pipeline_ids.count,
          skipped_for_old_age: @skipped_for_old_age,
          conservatively_cancelled: @conservatively_cancelled,
          aggressively_cancelled: @aggressively_cancelled,
          configured_to_not_cancel: @configured_to_not_cancel,
          canceled_by_pipeline_id: pipeline.id,
          project_id: pipeline.project_id,
          ref: pipeline.ref,
          sha: pipeline.sha
        )
      end

      def configured_cancellation_for(cancelable)
        case cancelable.auto_cancel_on_new_commit
        when 'none'
          # no-op

          @configured_to_not_cancel += 1
        when 'conservative'
          return unless conservative_cancellable_pipeline_ids.include?(cancelable.id)

          @conservatively_cancelled += 1

          cancel_pipeline(cancelable, safe_cancellation: false)
        when 'interruptible'

          @aggressively_cancelled += 1

          cancel_pipeline(cancelable, safe_cancellation: true)
        else
          raise ArgumentError,
            "Unknown auto_cancel_on_new_commit value: #{cancelable.auto_cancel_on_new_commit}"
        end
      end

      def conservative_cancellable_pipeline_ids
        cancelable_status_pipeline_ids.each_slice(ID_BATCH_SIZE).with_object([]) do |ids_batch, conservative_ids|
          conservative_ids.concat(::Ci::Pipeline.id_in(ids_batch).conservative_interruptible.ids) # rubocop:disable CodeReuse/ActiveRecord
        end
      end
      strong_memoize_attr :conservative_cancellable_pipeline_ids

      def cancel_pipeline(cancelable_pipeline, safe_cancellation:)
        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Pipeline #{pipeline.id} auto-canceling pipeline #{cancelable_pipeline.id}",
          canceled_pipeline_id: cancelable_pipeline.id,
          canceled_by_pipeline_id: pipeline.id,
          canceled_by_pipeline_source: pipeline.source
        )

        # cascade_to_children not needed because we iterate through descendants here
        ::Ci::CancelPipelineService.new(
          pipeline: cancelable_pipeline,
          current_user: nil,
          auto_canceled_by_pipeline: pipeline,
          cascade_to_children: false,
          safe_cancellation: safe_cancellation
        ).force_execute
      end

      def pipelines_created_after
        7.days.ago
      end

      # Finding the pipelines to cancel is an expensive task that is not well
      # covered by indexes for all project use-cases and sometimes it might
      # harm other services. See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/14758
      # This feature flag is in place to disable this feature for rogue projects.
      #
      def service_disabled?
        Feature.enabled?(:disable_cancel_redundant_pipelines_service, project, type: :ops)
      end
    end
  end
end
