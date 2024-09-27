# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteStalePackagesNpmMetadataCaches < BatchedMigrationJob
      operation_name :delete_all
      scope_to ->(relation) { relation.where(project_id: nil) }
      feature_category :package_registry

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.delete_all
        end
      end
    end
  end
end
