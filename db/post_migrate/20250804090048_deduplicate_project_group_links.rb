# frozen_string_literal: true

class DeduplicateProjectGroupLinks < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.3'

  def up
    model = define_batchable_model('project_group_links')

    # Single pass over the table
    model.each_batch do |batch|
      # Find duplicated (project_id, group_id) pairs
      # rubocop:disable GitlabSecurity/SqlInjection -- no user input
      duplicates = model
                     .where("(project_id, group_id) IN (#{batch.select(:project_id, :group_id).to_sql})")
                     .group(:project_id, :group_id)
                     .having('COUNT(*) > 1')
                     .pluck(:project_id, :group_id)
      # rubocop:enable GitlabSecurity/SqlInjection
      next if duplicates.empty?

      value_list = Arel::Nodes::ValuesList.new(duplicates).to_sql

      # Locate all records by (project_id, group_id) pairs and keep the most recent record.
      cleanup_query = <<~SQL
        WITH duplicated_records AS MATERIALIZED (
          SELECT
            id,
            ROW_NUMBER() OVER (PARTITION BY project_id, group_id ORDER BY project_id, group_id, id DESC) AS row_number
          FROM project_group_links
          WHERE (project_id, group_id) IN (#{value_list})
          ORDER BY project_id, group_id
        )
        DELETE FROM project_group_links
        WHERE id IN (
          SELECT id FROM duplicated_records WHERE row_number > 1
        )
      SQL

      model.connection.execute(cleanup_query)
    end
  end

  def down
    # no-op
  end
end
