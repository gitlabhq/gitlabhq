# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Database < Task
          def self.id = 'db'

          def human_name = _('databases')

          def destination_path = 'db'

          def cleanup_path = 'db'

          private

          def target
            ::Gitlab::Backup::Cli::Targets::Database.new(context)
          end
        end
      end
    end
  end
end
