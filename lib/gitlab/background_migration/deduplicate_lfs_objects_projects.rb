# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeduplicateLfsObjectsProjects < BatchedMigrationJob
      operation_name :deduplicates_lfs_objects_projects
      feature_category :source_code_management

      # Temporary class to link AR model to the `lfs_objects_projects` table
      class LfsObjectsProject < ::ApplicationRecord
        include EachBatch

        self.table_name = 'lfs_objects_projects'
      end

      def perform
        each_sub_batch do |relation|
          data = duplicates_by_project_id_and_lfs_object_id(relation)

          next if data.empty?

          # After plucking the duplicates, build a VALUE list
          id_list = Arel::Nodes::ValuesList.new(data).to_sql

          # Use the same GROUP BY query as in the MR to properly narrow down the duplicated records.
          # In the previous query we didn't include the repository_type because it is not covered with an index.
          subquery = LfsObjectsProject
                       .where("(project_id, lfs_object_id) IN (#{id_list})") # rubocop:disable GitlabSecurity/SqlInjection -- there is no user input given
                       .select('project_id, lfs_object_id, repository_type, MAX(id) AS max_id')
                       .group('project_id, lfs_object_id, repository_type')
                       .having('COUNT(*) > 1')

          join_query = <<~SQL.squish
            INNER JOIN (#{subquery.to_sql}) AS duplicates
            ON lfs_objects_projects.project_id = duplicates.project_id
            AND lfs_objects_projects.lfs_object_id = duplicates.lfs_object_id
            AND lfs_objects_projects.repository_type IS NOT DISTINCT FROM duplicates.repository_type
          SQL

          duplicated_lfs_objects_projects = LfsObjectsProject.joins(join_query).where.not(
            'lfs_objects_projects.id = duplicates.max_id'
          )

          LfsObjectsProject.where(id: duplicated_lfs_objects_projects.select(:id)).delete_all
        end
      end

      private

      def duplicates_by_project_id_and_lfs_object_id(relation)
        # Select project_id and lfs_object_id pairs which have duplicates.
        inner_query = LfsObjectsProject
                        .select('1')
                        .from('lfs_objects_projects lop')
                        .where('lop.project_id = lfs_objects_projects.project_id')
                        .where('lop.lfs_object_id = lfs_objects_projects.lfs_object_id')
                        .limit(2)

        count_query = LfsObjectsProject.select('COUNT(*) AS count').from("(#{inner_query.to_sql}) cnt")

        cte = Gitlab::SQL::CTE.new(:distinct_values, relation.select(:project_id, :lfs_object_id).distinct)

        # Limit count to determine if there is a duplicate, we don't need to load all duplicated rows
        # (only 2 rows are enough for a project_id, lfs_object_id) pair
        cte.apply_to(LfsObjectsProject.where({}))
           .where("(#{count_query.to_sql}) = 2") # rubocop:disable GitlabSecurity/SqlInjection -- there is no user input given
           .pluck(:project_id, :lfs_object_id)
      end
    end
  end
end
