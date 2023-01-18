# frozen_string_literal: true
# rubocop:disable Style/Documentation
module Gitlab
  module BackgroundMigration
    class BackfillProjectImportLevel < BatchedMigrationJob
      operation_name :update_import_level
      feature_category :database

      LEVEL = {
        Gitlab::Access::NO_ACCESS => [0],
        Gitlab::Access::DEVELOPER => [2],
        Gitlab::Access::MAINTAINER => [1],
        Gitlab::Access::OWNER => [nil]
      }.freeze

      def perform
        each_sub_batch do |sub_batch|
          update_import_level(sub_batch)
        end
      end

      private

      def update_import_level(relation)
        LEVEL.each do |import_level, creation_level|
          namespace_ids = relation
            .where(type: 'Group', project_creation_level: creation_level)

          NamespaceSetting.where(
            namespace_id: namespace_ids
          ).update_all(project_import_level: import_level)
        end
      end
    end
  end
end

# rubocop:enable Style/Documentation
