# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Repositories < Task
          def self.id = 'repositories'

          def human_name = _('repositories')

          def destination_path = 'repositories'

          def destination_optional = true

          private

          def target
            Gitlab::Backup::Cli::Targets::Repositories.new(context)
          end
        end
      end
    end
  end
end
