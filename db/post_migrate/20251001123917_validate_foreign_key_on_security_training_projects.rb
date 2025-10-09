# frozen_string_literal: true

class ValidateForeignKeyOnSecurityTrainingProjects < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    validate_foreign_key :security_trainings, :project_id, name: 'fk_rails_f80240fae0'
  end

  def down
    # no-op
  end
end
