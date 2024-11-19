# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkDuplicateIssuableResourceLinks < BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      operation_name :mark_de_duplicated_issuable_links_as_unique
      feature_category :database

      def perform
        distinct_each_batch do |batch|
          issue_ids = batch.pluck(batch_column)
          base_relation
            .where(batch_column => issue_ids)
            .select(:issue_id, :link)
            .group(:issue_id, :link)
            .having('count(*) > 1')
            .each do |dup|
              ids = base_relation
                .select(:id)
                .where(issue_id: dup.issue_id, link: dup.link)
                .order(:created_at)
                .pluck(:id)

              first = ids.shift # We take the first record created as the correct one and mark the others as duplicates
              base_relation.where(id: ids).update_all(is_unique: false)
              base_relation.update(first, is_unique: true)
            end
        end
      end

      private

      def base_relation
        define_batchable_model(batch_table, connection: connection, primary_key: :id)
          .where(batch_column => start_id..end_id)
      end
    end
  end
end
