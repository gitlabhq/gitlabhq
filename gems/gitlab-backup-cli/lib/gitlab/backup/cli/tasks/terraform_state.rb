# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class TerraformState < Task
          def self.id = 'terraform_state'

          def human_name = 'Terraform States'

          def destination_path = 'terraform_state.tar.gz'

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path, excludes: ['tmp'])
          end

          def storage_path = context.terraform_state_path
        end
      end
    end
  end
end
