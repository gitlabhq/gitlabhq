# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteDuplicateIssuableResourceLinks < BatchedMigrationJob
      operation_name :delete_duplicate_issuable_resource_links
      scope_to ->(relation) { relation.where(is_unique: false) }
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.delete_all
        end
      end
    end
  end
end
