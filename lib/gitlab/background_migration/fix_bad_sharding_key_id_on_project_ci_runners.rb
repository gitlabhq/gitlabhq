# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class FixBadShardingKeyIdOnProjectCiRunners < BatchedMigrationJob
      include Gitlab::Utils::StrongMemoize

      operation_name :fill_bad_sharding_key_id_on_project_ci_runners
      scope_to ->(relation) { relation.where(runner_type: 3) }

      feature_category :runner_core

      class CiRunner < ::Ci::ApplicationRecord
        self.table_name = 'ci_runners'
      end

      class CiRunnerProject < ::Ci::ApplicationRecord
        self.table_name = 'ci_runner_projects'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(sharding_key_id: nil)
            .where('NOT EXISTS (?)', runners_with_valid_sharding_keys.select(1))
            .where('EXISTS (?)', project_runner_owner.select(1))
            .update_all("sharding_key_id = (#{project_runner_owner.select(:project_id).to_sql})")
        end
      end

      private

      def runners_with_valid_sharding_keys
        CiRunnerProject
          .where("#{CiRunnerProject.table_name}.project_id = #{CiRunner.table_name}.sharding_key_id")
          .where("#{CiRunnerProject.table_name}.runner_id = #{CiRunner.table_name}.id")
      end
      strong_memoize_attr :runners_with_valid_sharding_keys

      def project_runner_owner
        CiRunnerProject
          .where("#{CiRunnerProject.table_name}.runner_id = #{CiRunner.table_name}.id")
          .order(id: :asc)
          .limit(1)
      end
    end
  end
end
