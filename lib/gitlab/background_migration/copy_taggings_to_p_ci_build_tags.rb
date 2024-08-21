# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CopyTaggingsToPCiBuildTags < BatchedMigrationJob
      operation_name :copy_taggings
      feature_category :continuous_integration

      COLUMN_NAMES = [:tag_id, :build_id, :partition_id, :project_id].freeze

      def perform
        each_sub_batch do |sub_batch|
          scope = sub_batch
            .where(taggable_type: 'CommitStatus')
            .joins('inner join p_ci_builds on p_ci_builds.id = taggings.taggable_id')
            .select(:tag_id, 'taggable_id as build_id', :partition_id, :project_id)

          connection.execute(<<~SQL.squish)
            INSERT INTO p_ci_build_tags(tag_id, build_id, partition_id, project_id)
            (#{scope.to_sql})
            ON CONFLICT DO NOTHING;
          SQL
        end
      end
    end
  end
end
