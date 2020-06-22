# frozen_string_literal: true

module Ci
  module PipelineProcessing
    class LegacyProcessingService
      include Gitlab::Utils::StrongMemoize

      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute(trigger_build_ids = nil, initial_process: false)
        success = process_stages_for_stage_scheduling

        # we evaluate dependent needs,
        # only when the another job has finished
        success = process_dag_builds_without_needs || success if initial_process
        success = process_dag_builds_with_needs(trigger_build_ids) || success

        @pipeline.update_legacy_status

        success
      end

      private

      def process_stages_for_stage_scheduling
        stage_indexes_of_created_stage_scheduled_processables.flat_map do |index|
          process_stage_for_stage_scheduling(index)
        end.any?
      end

      def process_stage_for_stage_scheduling(index)
        current_status = status_for_prior_stages(index)

        return unless Ci::HasStatus::COMPLETED_STATUSES.include?(current_status)

        created_stage_scheduled_processables_in_stage(index).find_each.select do |build|
          process_build(build, current_status)
        end.any?
      end

      def process_dag_builds_without_needs
        created_processables.scheduling_type_dag.without_needs.each do |build|
          process_build(build, 'success')
        end
      end

      def process_dag_builds_with_needs(trigger_build_ids)
        return false unless trigger_build_ids.present?

        # we find processables that are dependent:
        # 1. because of current dependency,
        trigger_build_names = pipeline.processables.latest
          .for_ids(trigger_build_ids).names

        # 2. does not have builds that not yet complete
        incomplete_build_names = pipeline.processables.latest
          .incomplete.names

        # Each found processable is guaranteed here to have completed status
        created_processables
          .scheduling_type_dag
          .with_needs(trigger_build_names)
          .without_needs(incomplete_build_names)
          .find_each
          .map(&method(:process_dag_build_with_needs))
          .any?
      end

      def process_dag_build_with_needs(build)
        current_status = status_for_build_needs(build.needs.map(&:name))

        return unless Ci::HasStatus::COMPLETED_STATUSES.include?(current_status)

        process_build(build, current_status)
      end

      def process_build(build, current_status)
        Gitlab::OptimisticLocking.retry_lock(build) do |subject|
          Ci::ProcessBuildService.new(project, subject.user)
            .execute(subject, current_status)
        end
      end

      def status_for_prior_stages(index)
        pipeline.processables.status_for_prior_stages(index, project: pipeline.project)
      end

      def status_for_build_needs(needs)
        pipeline.processables.status_for_names(needs, project: pipeline.project)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def stage_indexes_of_created_stage_scheduled_processables
        created_stage_scheduled_processables.order(:stage_idx)
          .pluck(Arel.sql('DISTINCT stage_idx'))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def created_stage_scheduled_processables_in_stage(index)
        created_stage_scheduled_processables
          .with_preloads
          .for_stage(index)
      end

      def created_stage_scheduled_processables
        created_processables.scheduling_type_stage
      end

      def created_processables
        pipeline.processables.created
      end

      def project
        pipeline.project
      end
    end
  end
end
