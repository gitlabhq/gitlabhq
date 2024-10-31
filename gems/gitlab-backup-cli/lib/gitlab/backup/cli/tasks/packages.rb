# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class Packages < Task
          def self.id = 'packages'

          def human_name = _('packages')

          def destination_path = 'packages.tar.gz'

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path, excludes: ['tmp'])
          end

          def storage_path = context.packages_path
        end
      end
    end
  end
end
