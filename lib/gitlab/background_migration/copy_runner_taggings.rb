# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CopyRunnerTaggings < BatchedMigrationJob
      operation_name :copy_runner_taggings
      feature_category :runner

      def perform
        each_sub_batch do |sub_batch|
          scope = sub_batch.where(runner_type: 1).or(sub_batch.where.not(sharding_key_id: nil))
          scope = scope
            .joins('inner join taggings on ci_runners.id = taggings.taggable_id')
            .joins('inner join ci_runners_e59bb2812d on ci_runners.id = ci_runners_e59bb2812d.id')
            .where(taggings: { taggable_type: 'Ci::Runner' })
            .select(:tag_id, 'taggable_id as runner_id', :sharding_key_id, :runner_type)

          connection.execute(<<~SQL.squish)
            INSERT INTO ci_runner_taggings(tag_id, runner_id, sharding_key_id, runner_type)
            (#{scope.to_sql})
            ON CONFLICT DO NOTHING;
          SQL
        end
      end
    end
  end
end
