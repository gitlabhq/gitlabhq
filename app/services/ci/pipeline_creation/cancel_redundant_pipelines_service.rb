# frozen_string_literal: true

module Ci
  module PipelineCreation
    class CancelRedundantPipelinesService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 25
      PAGE_SIZE = 500
      MAX_CANCELLATIONS_PER_PIPELINE = 3000
      PK_BATCH_SIZE = 1000

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

        cancelable_pipelines.each do |cancelable_pipe|
          configured_cancellation_for(cancelable_pipe)
        end

        log_cancelable_pipeline_outcomes
      end

      private

      attr_reader :pipeline, :project

      def cancelable_status_pipeline_pks
        project.all_pipelines
          .for_ref(pipeline.ref)
          .id_not_in(pipeline.id)
          .with_status(Ci::Pipeline::CANCELABLE_STATUSES)
          .order_id_desc # Query the most recently created cancellable Pipelines
          .limit(MAX_CANCELLATIONS_PER_PIPELINE)
          .pluck_primary_key
          .reverse # Once we have the most recent Pipelines, cancel oldest & upstreams first
      end
      strong_memoize_attr :cancelable_status_pipeline_pks

      def ref_head_sha
        project.commit(pipeline.ref).try(:id)
      end
      strong_memoize_attr :ref_head_sha

      def cancelable_pipelines
        cancelable_status_pipeline_pks.each_slice(PK_BATCH_SIZE).with_object([]) do |pks_batch, cancelables|
          Ci::Pipeline.primary_key_in(pks_batch).order_id_asc.each do |cancelable|
            next if should_skip?(cancelable)

            # Keep the actual Pipeline instantiated
            # so we can cancel it directly.
            cancelables << cancelable
          end
        end
      end

      def should_skip?(cancelable)
        case cancelable.source.to_sym
        when *Enums::Ci::Pipeline.ci_sources.keys
          # Newer pipelines are not cancelable. This doesn't normally occur
          # but needs to be handled in asynchronous execution.
          return true if cancelable.created_at >= pipeline.created_at
        when :parent_pipeline
          # Child pipelines are cancelable based on the root parent age
          return true if cancelable.root_ancestor.created_at >= pipeline.created_at
        else
          # Skip other pipeline sources
          return true
        end

        return true if cancelable.sha == pipeline.sha
        return true if cancelable.sha == ref_head_sha

        if cancelable.created_at < pipelines_created_after
          @skipped_for_old_age += 1

          return true
        end

        false
      end

      def configured_cancellation_for(cancelable)
        case cancelable.auto_cancel_on_new_commit
        when 'none'
          # no-op

          @configured_to_not_cancel += 1
        when 'conservative'
          return unless conservative_cancelable_pipeline_pks.include?(cancelable.id)

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

      def conservative_cancelable_pipeline_pks
        cancelable_status_pipeline_pks.each_slice(PK_BATCH_SIZE).with_object([]) do |pks_batch, conservative_pks|
          conservative_pks.concat(::Ci::Pipeline.primary_key_in(pks_batch).conservative_interruptible.pluck_primary_key)
        end
      end
      strong_memoize_attr :conservative_cancelable_pipeline_pks

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

      def log_cancelable_pipeline_outcomes
        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Canceling redundant pipelines",
          cancellable_count: cancelable_status_pipeline_pks.count,
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
