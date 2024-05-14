# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Commands
        class Command < Thor
          def self.exit_on_failure? = true

          # Define the command basename instead of relying on $PROGRAM_NAME
          # This ensures the output is the same even inside RSpec
          def self.basename = 'gitlab-backup-cli'
        end
      end
    end
  end
end
