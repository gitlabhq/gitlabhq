# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class FileRestoreError < StandardError
          attr_reader :error_message

          def initialize(error_message:)
            @error_message = error_message

            super(build_message)
          end

          private

          def build_message
            "Restore operation failed: #{error_message}"
          end
        end
      end
    end
  end
end
