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
        # Workaround for weird Rails bug, that makes `runner.groups.to_sql` to return `runner_id = NULL`
        groups = ::Group.joins(:runner_namespaces).merge(runner.runner_namespaces)

        hierarchy_groups = Gitlab::ObjectHierarchy
          .new(groups)
          .base_and_descendants

        projects = Project.where(namespace_id: hierarchy_groups)
          .with_group_runners_enabled
          .with_builds_enabled
          .without_deleted

        relation = new_builds.where(project: projects)

        order(relation)
      end

      def builds_for_project_runner
        relation = new_builds
          .where(project: runner.projects.without_deleted.with_builds_enabled)

        order(relation)
      end

      def builds_queued_before(relation, time)
        relation.queued_before(time)
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
        strategy.build_ids(relation)
      end

      private

      def strategy
        strong_memoize(:strategy) do
          if ::Feature.enabled?(:ci_pending_builds_queue_source, runner, default_enabled: :yaml)
            Queue::PendingBuildsStrategy.new(runner)
          else
            Queue::BuildsTableStrategy.new(runner)
          end
        end
      end
    end
  end
end

Ci::Queue::BuildQueueService.prepend_mod_with('Ci::Queue::BuildQueueService')
