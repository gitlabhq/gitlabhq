# frozen_string_literal: true

module Ci
  module Queue
    class BuildQueueService
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :runner, :runner_manager

      def initialize(runner, runner_manager = nil)
        @runner = runner
        @runner_manager = runner_manager
      end

      def new_builds
        strategy.new_builds
      end

      def build_candidates
        candidates =
          if runner.project_type?
            builds_for_project_runner
          elsif runner.group_type?
            builds_for_group_runner
          else
            builds_for_shared_runner
          end

        candidates = builds_for_protected_runner(candidates) if runner.ref_protected?

        if ::Feature.enabled?(:ci_pending_builds_runner_machine_id_filter, runner, type: :gitlab_com_derisk)
          candidates = builds_for_runner_manager(candidates)
        end

        # pick builds that does not have other tags than runner's one
        candidates = builds_matching_tag_ids(candidates, runner.tagging_tag_ids)

        # pick builds that have at least one tag
        candidates = builds_with_any_tags(candidates) unless runner.run_untagged?

        candidates
      end

      ##
      # This is overridden in EE
      #
      def builds_for_shared_runner
        strategy.builds_for_shared_runner
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def builds_for_group_runner
        strategy.builds_for_group_runner
      end

      def builds_for_project_runner
        relation = new_builds
          .where(project: runner_projects_relation)

        order(relation)
      end

      def builds_for_protected_runner(relation)
        relation.ref_protected
      end

      def builds_for_runner_manager(relation)
        strategy.builds_for_runner_manager(relation, runner_manager)
      end

      def builds_matching_tag_ids(relation, ids)
        strategy.builds_matching_tag_ids(relation, ids)
      end

      def builds_with_any_tags(relation)
        strategy.builds_with_any_tags(relation)
      end

      def order(relation)
        strategy.order(relation)
      end

      def execute(relation)
        if ::Feature.enabled?(:ci_pending_builds_runner_machine_id_filter, runner, type: :gitlab_com_derisk)
          strategy.build_partition_and_project_ids(relation)
        else
          strategy.build_and_partition_ids(relation)
        end
      end

      private

      def strategy
        strong_memoize(:strategy) do
          Queue::PendingBuildsStrategy.new(runner)
        end
      end

      def runner_projects_relation
        runner
          .runner_projects
          .select('"ci_runner_projects"."project_id"::bigint')
      end
    end
  end
end

Ci::Queue::BuildQueueService.prepend_mod_with('Ci::Queue::BuildQueueService')
