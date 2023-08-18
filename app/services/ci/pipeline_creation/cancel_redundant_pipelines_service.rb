# frozen_string_literal: true

module Ci
  module PipelineCreation
    class CancelRedundantPipelinesService
      include Gitlab::Utils::StrongMemoize

      BATCH_SIZE = 25
      PAGE_SIZE = 500

      def initialize(pipeline)
        @pipeline = pipeline
        @project = @pipeline.project
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return if service_disabled?
        return if pipeline.parent_pipeline? # skip if child pipeline
        return unless project.auto_cancel_pending_pipelines?

        if Feature.enabled?(:use_offset_pagination_for_canceling_redundant_pipelines, project)
          paginator.each do |ids|
            pipelines = parent_and_child_pipelines(ids)

            Gitlab::OptimisticLocking.retry_lock(pipelines, name: 'cancel_pending_pipelines') do |cancelables|
              auto_cancel_interruptible_pipelines(cancelables.ids)
            end
          end
        else
          Gitlab::OptimisticLocking
            .retry_lock(parent_and_child_pipelines, name: 'cancel_pending_pipelines') do |cancelables|
            cancelables.select(:id).each_batch(of: BATCH_SIZE) do |cancelables_batch|
              auto_cancel_interruptible_pipelines(cancelables_batch.ids)
            end
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

      def parent_auto_cancelable_pipelines(ids = nil)
        scope = project.all_pipelines
          .created_after(pipelines_created_after)
          .for_ref(pipeline.ref)
          .where_not_sha(project.commit(pipeline.ref).try(:id))
          .where("created_at < ?", pipeline.created_at)
          .for_status(CommitStatus::AVAILABLE_STATUSES) # Force usage of project_id_and_status_and_created_at_index
          .ci_sources

        scope = scope.id_in(ids) if ids.present?
        scope
      end

      def parent_and_child_pipelines(ids = nil)
        Ci::Pipeline.object_hierarchy(parent_auto_cancelable_pipelines(ids), project_condition: :same)
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
            ::Ci::CancelPipelineService.new(
              pipeline: cancelable_pipeline,
              current_user: nil,
              auto_canceled_by_pipeline_id: pipeline.id,
              cascade_to_children: false
            ).force_execute
          end
      end

      def pipelines_created_after
        if Feature.enabled?(:lower_interval_for_canceling_redundant_pipelines, project)
          3.days.ago
        else
          1.week.ago
        end
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
