# frozen_string_literal: true

class DeduplicateProjectRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    model = define_batchable_model('project_repository_states')

    model.each_batch do |batch|
      duplicates = model
                     .where(project_repository_id: batch.select(:project_repository_id))
                     .group(:project_repository_id)
                     .having('COUNT(*) > 1')
                     .pluck(:project_repository_id)
      next if duplicates.empty?

      cleanup_query = <<~SQL
        WITH duplicated_records AS MATERIALIZED (
          SELECT
            id,
            ROW_NUMBER() OVER (PARTITION BY project_repository_id ORDER BY id DESC) AS row_number
          FROM project_repository_states
          WHERE project_repository_id IN (#{duplicates.map { |id| connection.quote(id) }.join(', ')})
        )
        DELETE FROM project_repository_states
        WHERE id IN (
          SELECT id FROM duplicated_records WHERE row_number > 1
        )
      SQL

      execute(cleanup_query)
    end
  end

  def down
    # no-op
  end
end
