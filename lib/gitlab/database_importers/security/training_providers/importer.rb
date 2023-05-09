# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module Security
      module TrainingProviders
        module Importer
          KONTRA_DATA = {
            name: 'Kontra',
            description: "Kontra Application Security provides interactive developer security education that
                          enables engineers to quickly learn security best practices
                          and fix issues in their code by analysing real-world software security vulnerabilities.",
            url: "https://application.security/api/webhook/gitlab/exercises/search"
          }.freeze

          SCW_DATA = {
            name: 'Secure Code Warrior',
            description: "Resolve vulnerabilities faster and confidently with
                          highly relevant and bite-sized secure coding learning.",
            url: "https://integration-api.securecodewarrior.com/api/v1/trial"
          }.freeze

          SECUREFLAG_DATA = {
            name: 'SecureFlag',
            description: "Get remediation advice with example code and recommended hands-on labs in a fully
                          interactive virtualised environment.",
            url: "https://knowledge-base-api.secureflag.com/gitlab"
          }.freeze

          module Security
            class TrainingProvider < ApplicationRecord
              self.table_name = 'security_training_providers'
            end
          end

          def self.upsert_providers
            current_time = Time.current
            timestamps = { created_at: current_time, updated_at: current_time }

            Security::TrainingProvider.upsert_all(
              [KONTRA_DATA.merge(timestamps), SCW_DATA.merge(timestamps), SECUREFLAG_DATA.merge(timestamps)],
              unique_by: :index_security_training_providers_on_unique_name
            )
          end
        end
      end
    end
  end
end
