# frozen_string_literal: true

module Ci
  module Queue
    class PendingBuildsStrategy
      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def builds_for_shared_runner
        shared_builds = builds_available_for_shared_runners

        builds_ordered_for_shared_runners(shared_builds)
      end

      def builds_for_group_runner
        return new_builds.none if runner.namespace_ids.empty?

        new_builds_relation = new_builds.where("ci_pending_builds.namespace_traversal_ids && '{?}'", runner.namespace_ids)

        order(new_builds_relation)
      end

      def builds_matching_tag_ids(relation, ids)
        relation.for_tags(runner.tags_ids)
      end

      def builds_with_any_tags(relation)
        relation.where('cardinality(tag_ids) > 0')
      end

      def order(relation)
        relation.order('build_id ASC')
      end

      def new_builds
        ::Ci::PendingBuild.all
      end

      def build_and_partition_ids(relation)
        relation.pluck(:build_id, :partition_id)
      end

      private

      def builds_available_for_shared_runners
        new_builds.with_instance_runners
      end

      def builds_ordered_for_shared_runners(relation)
        if Feature.enabled?(:ci_queueing_disaster_recovery_disable_fair_scheduling, runner, type: :ops)
          # if disaster recovery is enabled, we fallback to FIFO scheduling
          relation.order('ci_pending_builds.build_id ASC')
        else
          # Implements Fair Scheduling
          # Builds are ordered by projects that have the fewest running builds.
          # This keeps projects that create many builds at once from hogging capacity but
          # has the downside of penalizing projects with lots of builds created in a short period of time
          relation
            .with(running_builds_for_shared_runners_cte.to_arel)
            .joins("LEFT JOIN project_builds ON ci_pending_builds.project_id = project_builds.project_id")
            .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_pending_builds.build_id ASC')
        end
      end

      def running_builds_for_shared_runners_cte
        running_builds = ::Ci::RunningBuild
          .instance_type
          .group(:project_id)
          .select(:project_id, 'COUNT(*) AS running_builds')

        ::Gitlab::SQL::CTE
          .new(:project_builds, running_builds, materialized: true)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end

Ci::Queue::PendingBuildsStrategy.prepend_mod_with('Ci::Queue::PendingBuildsStrategy')
