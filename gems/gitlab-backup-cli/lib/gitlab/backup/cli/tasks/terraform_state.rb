# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class TerraformState < Task
          def self.id = 'terraform_state'

          def human_name = _('terraform states')

          def destination_path = 'terraform_state.tar.gz'

          private

          def target
            ::Backup::Targets::Files.new(nil, storage_path, options: options, excludes: ['tmp'])
          end

          def storage_path = context.terraform_state_path
        end
      end
    end
  end
end
