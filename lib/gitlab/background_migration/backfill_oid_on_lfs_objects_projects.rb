# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOidOnLfsObjectsProjects < BatchedMigrationJob
      operation_name :backfill_lfs_objects_projects_oid
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          lfs_obj_proj_ids = sub_batch.select(:id).map(&:id).join(', ')

          connection.execute(
            <<~SQL
              UPDATE "lfs_objects_projects"
              SET
                "oid" = "lfs_objects"."oid"
              FROM
                "lfs_objects"
              WHERE
                "lfs_objects_projects"."oid" IS NULL
                AND "lfs_objects_projects"."lfs_object_id" = "lfs_objects"."id"
                AND "lfs_objects_projects"."id" IN (#{lfs_obj_proj_ids})
            SQL
          )
        end
      end
    end
  end
end
