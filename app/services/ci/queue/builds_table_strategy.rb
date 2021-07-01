# frozen_string_literal: true

module Ci
  module Queue
    class BuildsTableStrategy
      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      # rubocop:disable CodeReuse/ActiveRecord
      def builds_for_shared_runner
        relation = new_builds
          # don't run projects which have not enabled shared runners and builds
          .joins('INNER JOIN projects ON ci_builds.project_id = projects.id')
          .where(projects: { shared_runners_enabled: true, pending_delete: false })
          .joins('LEFT JOIN project_features ON ci_builds.project_id = project_features.project_id')
          .where('project_features.builds_access_level IS NULL or project_features.builds_access_level > 0')

        if Feature.enabled?(:ci_queueing_disaster_recovery_disable_fair_scheduling, runner, type: :ops, default_enabled: :yaml)
          # if disaster recovery is enabled, we fallback to FIFO scheduling
          relation.order('ci_builds.id ASC')
        else
          # Implement fair scheduling
          # this returns builds that are ordered by number of running builds
          # we prefer projects that don't use shared runners at all
          relation
            .joins("LEFT JOIN (#{running_builds_for_shared_runners.to_sql}) AS project_builds ON ci_builds.project_id = project_builds.project_id")
            .order(Arel.sql('COALESCE(project_builds.running_builds, 0) ASC'), 'ci_builds.id ASC')
        end
      end

      def builds_matching_tag_ids(relation, ids)
        # pick builds that does not have other tags than runner's one
        relation.matches_tag_ids(ids)
      end

      def builds_with_any_tags(relation)
        # pick builds that have at least one tag
        relation.with_any_tags
      end

      def order(relation)
        relation.order('id ASC')
      end

      def new_builds
        ::Ci::Build.pending.unstarted
      end

      def build_ids(relation)
        relation.pluck(:id)
      end

      private

      def running_builds_for_shared_runners
        ::Ci::Build.running
          .where(runner: ::Ci::Runner.instance_type)
          .group(:project_id)
          .select(:project_id, 'COUNT(*) AS running_builds')
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
