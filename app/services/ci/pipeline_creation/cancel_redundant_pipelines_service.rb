# frozen_string_literal: true

module Ci
  module PipelineCreation
    class CancelRedundantPipelinesService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 25

      def initialize(pipeline)
        @pipeline = pipeline
        @project = @pipeline.project
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return if pipeline.parent_pipeline? # skip if child pipeline
        return unless project.auto_cancel_pending_pipelines?

        Gitlab::OptimisticLocking
        .retry_lock(parent_and_child_pipelines, name: 'cancel_pending_pipelines') do |cancelables|
          cancelables.select(:id).each_batch(of: BATCH_SIZE) do |cancelables_batch|
            auto_cancel_interruptible_pipelines(cancelables_batch.ids)
          end
        end
      end

      private

      attr_reader :pipeline, :project

      def parent_auto_cancelable_pipelines
        project.all_pipelines
          .created_after(1.week.ago)
          .for_ref(pipeline.ref)
          .where_not_sha(project.commit(pipeline.ref).try(:id))
          .where("created_at < ?", pipeline.created_at)
          .ci_sources
      end

      def parent_and_child_pipelines
        Ci::Pipeline.object_hierarchy(parent_auto_cancelable_pipelines, project_condition: :same)
          .base_and_descendants
          .alive_or_scheduled
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def auto_cancel_interruptible_pipelines(pipeline_ids)
        ::Ci::Pipeline
          .id_in(pipeline_ids)
          .with_only_interruptible_builds
          .each do |cancelable_pipeline|
            Gitlab::AppLogger.info(
              class: self.class.name,
              message: "Pipeline #{pipeline.id} auto-canceling pipeline #{cancelable_pipeline.id}",
              canceled_pipeline_id: cancelable_pipeline.id,
              canceled_by_pipeline_id: pipeline.id,
              canceled_by_pipeline_source: pipeline.source
            )

            # cascade_to_children not needed because we iterate through descendants here
            cancelable_pipeline.cancel_running(
              auto_canceled_by_pipeline_id: pipeline.id,
              cascade_to_children: false
            )
          end
      end
    end
  end
end
