# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class FileRestoreError < StandardError
          attr_reader :error_message

          def initialize(error_message:)
            super
            @error_message = error_message
          end

          def message
            "Restore operation failed: #{error_message}"
          end
        end
      end
    end
  end
end
