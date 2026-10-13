# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiNamespaceMirrorsOrganizationId < BatchedMigrationJob
      cursor :id

      operation_name :backfill_ci_namespace_mirrors_organization_id
      feature_category :continuous_integration

      class Namespace < ::ApplicationRecord
        self.table_name = 'namespaces'
        self.inheritance_column = :_type_disabled
      end

      def perform
        each_sub_batch do |sub_batch|
          mirror_ids_by_namespace_id = sub_batch
            .where(organization_id: nil)
            .pluck(:id, :namespace_id)
            .group_by(&:last)
            .transform_values { |pairs| pairs.map(&:first) }
          next if mirror_ids_by_namespace_id.empty?

          # namespaces lives on the main database, so the mapping is looked up
          # in Ruby and applied to the sub-batch with one UPDATE ... FROM (VALUES).
          values = Namespace
            .where(id: mirror_ids_by_namespace_id.keys)
            .where.not(organization_id: nil)
            .pluck(:id, :organization_id)
            .flat_map do |namespace_id, organization_id|
              mirror_ids_by_namespace_id[namespace_id].map do |mirror_id|
                "(#{Integer(mirror_id)}, #{Integer(organization_id)})"
              end
            end
          next if values.empty?

          connection.execute(<<~SQL)
            UPDATE ci_namespace_mirrors
            SET organization_id = mapping.organization_id
            FROM (VALUES #{values.join(', ')}) AS mapping(id, organization_id)
            WHERE ci_namespace_mirrors.id = mapping.id
              AND ci_namespace_mirrors.organization_id IS NULL
          SQL
        end
      end
    end
  end
end
