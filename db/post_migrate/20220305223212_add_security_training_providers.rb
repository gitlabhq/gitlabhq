# frozen_string_literal: true

class AddSecurityTrainingProviders < Gitlab::Database::Migration[1.0]
  KONTRA_DATA = {
    name: 'Kontra',
    description: "Kontra Application Security provides interactive developer security education that
                  enables engineers to quickly learn security best practices
                  and fix issues in their code by analysing real-world software security vulnerabilities.",
    url: "https://application.security/api/webhook/gitlab/exercises/search"
  }

  SCW_DATA = {
    name: 'Secure Code Warrior',
    description: "Resolve vulnerabilities faster and confidently with highly relevant and bite-sized secure coding learning.",
    url: "https://integration-api.securecodewarrior.com/api/v1/trial"
  }

  module Security
    class TrainingProvider < ActiveRecord::Base
      self.table_name = 'security_training_providers'
    end
  end

  def up
    current_time = Time.current
    timestamps = { created_at: current_time, updated_at: current_time }

    Security::TrainingProvider.reset_column_information

    # upsert providers
    Security::TrainingProvider.upsert_all([KONTRA_DATA.merge(timestamps), SCW_DATA.merge(timestamps)])
  end

  def down
    Security::TrainingProvider.reset_column_information

    Security::TrainingProvider.find_by(name: KONTRA_DATA[:name])&.destroy
    Security::TrainingProvider.find_by(name: SCW_DATA[:name])&.destroy
  end
end
