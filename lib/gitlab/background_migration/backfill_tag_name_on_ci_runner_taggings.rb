# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTagNameOnCiRunnerTaggings < BatchedMigrationJob
      operation_name :backfill_tag_name_on_ci_runner_taggings
      feature_category :runner_core

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('ci_runner_taggings.tag_id = tags.id')
            .where(tag_name: nil)
            .update_all('tag_name = tags.name FROM tags')
        end
      end
    end
  end
end
