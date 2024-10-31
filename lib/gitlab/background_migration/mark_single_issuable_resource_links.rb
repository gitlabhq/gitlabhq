# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkSingleIssuableResourceLinks < BatchedMigrationJob
      operation_name :mark_single_issuable_resource_links_as_unique
      feature_category :database

      def perform
        distinct_each_batch do |batch|
          issue_ids = batch.pluck(batch_column)
          base_relation
            .where(batch_column => issue_ids)
            .select(:issue_id, :link)
            .group(:issue_id, :link)
            .having('count(*) = 1')
            .each do |dup|
              ids = base_relation
                .select(:id)
                .where(issue_id: dup.issue_id, link: dup.link)
                .order(:created_at)
                .pluck(:id)

              first = ids.shift
              base_relation.where(id: first).update!(is_unique: true)
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
