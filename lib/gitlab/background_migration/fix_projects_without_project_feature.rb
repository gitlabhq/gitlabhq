# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration creates missing project_features records
    # for the projects within the given range of ids
    class FixProjectsWithoutProjectFeature
      def perform(from_id, to_id)
        if number_of_created_records = create_missing!(from_id, to_id) > 0
          log(number_of_created_records, from_id, to_id)
        end
      end

      private

      def create_missing!(from_id, to_id)
        result = ActiveRecord::Base.connection.select_one(sql(from_id, to_id))
        return 0 unless result

        result['number_of_created_records']
      end

      def sql(from_id, to_id)
        <<~SQL
          WITH created_records AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            INSERT INTO project_features (
              project_id,
              merge_requests_access_level,
              issues_access_level,
              wiki_access_level,
              snippets_access_level,
              builds_access_level,
              repository_access_level,
              forking_access_level,
              pages_access_level,
              created_at,
              updated_at
            )
              SELECT projects.id,
                20, 20, 20, 20, 20, 20, 20,
                #{pages_access_level},
                TIMEZONE('UTC', NOW()), TIMEZONE('UTC', NOW())
              FROM projects
              WHERE projects.id BETWEEN #{Integer(from_id)} AND #{Integer(to_id)}
              AND NOT EXISTS (
                SELECT 1 FROM project_features
                WHERE project_features.project_id = projects.id
              )
            ON CONFLICT (project_id) DO NOTHING
            RETURNING *
          )
          SELECT COUNT(*) as number_of_created_records
          FROM created_records
        SQL
      end

      def pages_access_level
        if ::Gitlab::Pages.access_control_is_forced?
          "10"
        else
          "GREATEST(projects.visibility_level, 10)"
        end
      end

      def log(count, from_id, to_id)
        logger = Gitlab::BackgroundMigration::Logger.build

        logger.info(message: "FixProjectsWithoutProjectFeature: created missing project_features for #{count} projects in id=#{from_id}...#{to_id}")
      end
    end
  end
end
