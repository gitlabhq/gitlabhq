# frozen_string_literal: true

class DropInvalidSecurityTrainingRecords < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '18.5'

  def up
    define_batchable_model(:security_trainings).each_batch(of: 500) do |batch|
      security_trainings_with_non_existing_project = batch.where(
        'NOT EXISTS (:projects)',
        projects: Project.select('1').where('security_trainings.project_id = projects.id')
      )

      security_trainings_with_non_existing_project.delete_all
    end
  end

  def down
    # no-op
  end
end
