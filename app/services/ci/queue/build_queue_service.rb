# frozen_string_literal: true

module Ci
  module Queue
    class BuildQueueService
      include ::Gitlab::Utils::StrongMemoize

      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      def new_builds
        strategy.new_builds
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
        strategy.build_and_partition_ids(relation)
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
