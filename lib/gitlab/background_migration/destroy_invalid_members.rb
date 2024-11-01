# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DestroyInvalidMembers < Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation.where(member_namespace_id: nil) }
      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          deleted_members_data = sub_batch.map do |m|
            { id: m.id, source_id: m.source_id, source_type: m.source_type, access_level: m.access_level }
          end

          deleted_count = sub_batch.delete_all

          Gitlab::AppLogger.info({ message: 'Removing invalid member records',
                                   deleted_count: deleted_count,
                                   deleted_member_data: deleted_members_data })
        end
      end
    end
  end
end
