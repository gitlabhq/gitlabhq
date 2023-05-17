# frozen_string_literal: true

class AddSecureflagTrainingProvider < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  SECUREFLAG_DATA = {
    name: 'SecureFlag',
    description: "Get remediation advice with example code and recommended hands-on labs in a fully
    interactive virtualised environment.",
    url: "https://knowledge-base-api.secureflag.com/gitlab"
  }

  class TrainingProvider < MigrationRecord
    self.table_name = 'security_training_providers'
  end

  def up
    current_time = Time.current
    timestamps = { created_at: current_time, updated_at: current_time }

    TrainingProvider.reset_column_information
    TrainingProvider.upsert(SECUREFLAG_DATA.merge(timestamps))
  end

  def down
    TrainingProvider.reset_column_information
    TrainingProvider.find_by(name: SECUREFLAG_DATA[:name])&.destroy
  end
end
