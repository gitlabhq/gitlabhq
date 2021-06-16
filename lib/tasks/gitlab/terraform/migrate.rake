# frozen_string_literal: true

require 'logger'

desc "GitLab | Terraform | Migrate Terraform states to remote storage"
namespace :gitlab do
  namespace :terraform_states do
    task migrate: :environment do
      logger = Logger.new($stdout)
      logger.info('Starting transfer of Terraform states to object storage')

      begin
        Gitlab::Terraform::StateMigrationHelper.migrate_to_remote_storage do |state_version|
          message = "Transferred Terraform state version ID #{state_version.id} (#{state_version.terraform_state.name}/#{state_version.version}) to object storage"

          logger.info(message)
        end
      rescue StandardError => e
        logger.error("Failed to migrate: #{e.message}")
      end
    end
  end
end
