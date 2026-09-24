# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiProjectMirrorsOrganizationId < BatchedMigrationJob
      cursor :id

      operation_name :backfill_ci_project_mirrors_organization_id
      feature_category :continuous_integration

      class Project < ::ApplicationRecord
        self.table_name = 'projects'
      end

      def perform
        each_sub_batch do |sub_batch|
          mirror_ids_by_project_id = sub_batch
            .where(organization_id: nil)
            .pluck(:id, :project_id)
            .group_by(&:last)
            .transform_values { |pairs| pairs.map(&:first) }
          next if mirror_ids_by_project_id.empty?

          # projects lives on the main database, so the mapping is looked up
          # in Ruby and applied to the sub-batch with one UPDATE ... FROM (VALUES).
          values = Project
            .where(id: mirror_ids_by_project_id.keys)
            .where.not(organization_id: nil)
            .pluck(:id, :organization_id)
            .flat_map do |project_id, organization_id|
              mirror_ids_by_project_id[project_id].map do |mirror_id|
                "(#{Integer(mirror_id)}, #{Integer(organization_id)})"
              end
            end
          next if values.empty?

          connection.execute(<<~SQL)
            UPDATE ci_project_mirrors
            SET organization_id = mapping.organization_id
            FROM (VALUES #{values.join(', ')}) AS mapping(id, organization_id)
            WHERE ci_project_mirrors.id = mapping.id
              AND ci_project_mirrors.organization_id IS NULL
          SQL
        end
      end
    end
  end
end
