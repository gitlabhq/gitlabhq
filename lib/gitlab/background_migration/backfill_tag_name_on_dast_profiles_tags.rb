# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTagNameOnDastProfilesTags < BatchedMigrationJob
      operation_name :backfill_tag_name_on_dast_profiles_tags
      feature_category :dynamic_application_security_testing

      class Tag < ::Ci::ApplicationRecord
        self.table_name = 'tags'
      end

      def perform
        each_sub_batch do |sub_batch|
          tag_ids = sub_batch.where(tag_name: nil).pluck(:tag_id).uniq
          next if tag_ids.empty?

          tag_names = Tag.where(id: tag_ids).pluck(:id, :name).to_h

          tag_names.each do |tag_id, name|
            sub_batch.where(tag_id: tag_id, tag_name: nil).update_all(tag_name: name)
          end
        end
      end
    end
  end
end
