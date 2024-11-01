# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DestroyInvalidGroupMembers < Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) do
        relation.where(source_type: 'Namespace')
                .joins('LEFT OUTER JOIN namespaces ON members.source_id = namespaces.id')
                .where(namespaces: { id: nil })
      end

      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          invalid_ids = sub_batch.map(&:id)
          Gitlab::AppLogger.info({ message: 'Removing invalid group member records',
                                   deleted_count: invalid_ids.size, ids: invalid_ids })

          sub_batch.delete_all
        end
      end
    end
  end
end
