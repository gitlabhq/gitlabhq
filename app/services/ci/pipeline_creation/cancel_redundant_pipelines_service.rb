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
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return if service_disabled?
        return if pipeline.parent_pipeline? # skip if child pipeline
        return unless project.auto_cancel_pending_pipelines?

        if Feature.enabled?(:cancel_redundant_pipelines_without_hierarchy_cte, @project)
          auto_cancel_all_pipelines_with_cancelable_statuses

          return
        end

        paginator.each do |ids|
          pipelines = parent_and_child_pipelines(ids)

          Gitlab::OptimisticLocking.retry_lock(pipelines, name: 'cancel_pending_pipelines') do |cancelables|
            auto_cancel_pipelines(cancelables.ids)
          end
        end
      end

      private

      attr_reader :pipeline, :project

      def paginator
        page = 1
        Enumerator.new do |yielder|
          loop do
            # leverage the index_ci_pipelines_on_project_id_and_status_and_created_at index
            records = project.all_pipelines
              .created_after(pipelines_created_after)
              .order(:status, :created_at)
              .page(page) # use offset pagination because there is no other way to loop over the data
              .per(PAGE_SIZE)
              .pluck(:id)

            raise StopIteration if records.empty?

            yielder << records
            page += 1
          end
        end
      end

      def parent_auto_cancelable_pipelines(ids)
        scope = project.all_pipelines
          .created_after(pipelines_created_after)
          .for_ref(pipeline.ref)
          .where_not_sha(project.commit(pipeline.ref).try(:id))
          .where("created_at < ?", pipeline.created_at)
          .for_status(CommitStatus::AVAILABLE_STATUSES) # Force usage of project_id_and_status_and_created_at_index
          .ci_sources

        scope.id_in(ids)
      end

      def parent_and_child_pipelines(ids)
        Ci::Pipeline.object_hierarchy(parent_auto_cancelable_pipelines(ids), project_condition: :same)
          .base_and_descendants
          .cancelable
      end

      def cancelable_status_pipeline_ids
        project.all_pipelines
          .for_ref(pipeline.ref)
          .id_not_in(pipeline.id)
          .with_status(Ci::Pipeline::CANCELABLE_STATUSES)
          .order_id_desc # Query the most recently created cancellable Pipelines
          .limit(MAX_CANCELLATIONS_PER_PIPELINE)
          .pluck(:id)
          .reverse # Once we have the most recent Pipelines, cancel oldest & upstreams first
      end
      strong_memoize_attr :cancelable_status_pipeline_ids

      def ref_head_sha
        project.commit(pipeline.ref).try(:id)
      end
      strong_memoize_attr :ref_head_sha

      # rubocop:disable Metrics/CyclomaticComplexity -- Keep logic tightly bound while this is still experimental
      def auto_cancel_all_pipelines_with_cancelable_statuses
        skipped_for_old_age      = 0
        conservatively_cancelled = 0
        aggressively_cancelled   = 0
        configured_to_not_cancel = 0

        cancelable_status_pipeline_ids.each_slice(ID_BATCH_SIZE) do |ids_batch|
          Ci::Pipeline.id_in(ids_batch).order_id_asc.each do |cancelable|
            case cancelable.source.to_sym
            when *Enums::Ci::Pipeline.ci_sources.keys
              # Newer pipelines are not cancelable
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
              skipped_for_old_age += 1

              next
            end

            # Cancel method based on configured strategy
            case cancelable.auto_cancel_on_new_commit
            when 'none'
              # no-op

              configured_to_not_cancel += 1
            when 'conservative'
              next unless conservative_cancellable_pipeline_ids(ids_batch).include?(cancelable.id)

              conservatively_cancelled += 1

              cancel_pipeline(cancelable, safe_cancellation: false)
            when 'interruptible'

              aggressively_cancelled += 1

              cancel_pipeline(cancelable, safe_cancellation: true)
            else
              raise ArgumentError,
                "Unknown auto_cancel_on_new_commit value: #{cancelable.auto_cancel_on_new_commit}"
            end
          end
        end

        Gitlab::AppLogger.info(
          class: self.class.name,
          message: "Canceling redundant pipelines",
          cancellable_count: cancelable_status_pipeline_ids.count,
          skipped_for_old_age: skipped_for_old_age,
          conservatively_cancelled: conservatively_cancelled,
          aggressively_cancelled: aggressively_cancelled,
          configured_to_not_cancel: configured_to_not_cancel,
          canceled_by_pipeline_id: pipeline.id,
          project_id: pipeline.project_id,
          ref: pipeline.ref,
          sha: pipeline.sha
        )
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def auto_cancel_pipelines(pipeline_ids)
        ::Ci::Pipeline
          .id_in(pipeline_ids)
          .each do |cancelable_pipeline|
            case cancelable_pipeline.auto_cancel_on_new_commit
            when 'none'
              # no-op
            when 'conservative'
              next unless conservative_cancellable_pipeline_ids(pipeline_ids).include?(cancelable_pipeline.id)

              cancel_pipeline(cancelable_pipeline, safe_cancellation: false)
            when 'interruptible'
              cancel_pipeline(cancelable_pipeline, safe_cancellation: true)
            else
              raise ArgumentError,
                "Unknown auto_cancel_on_new_commit value: #{cancelable_pipeline.auto_cancel_on_new_commit}"
            end
          end
      end

      def conservative_cancellable_pipeline_ids(pipeline_ids)
        strong_memoize_with(:conservative_cancellable_pipeline_ids, pipeline_ids) do
          ::Ci::Pipeline.id_in(pipeline_ids).conservative_interruptible.ids
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

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
        3.days.ago
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
