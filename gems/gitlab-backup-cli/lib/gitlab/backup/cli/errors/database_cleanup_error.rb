# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class DatabaseCleanupError < StandardError
          attr_reader :task, :path, :error

          def initialize(task:, path:, error:)
            @task = task
            @path = path
            @error = error

            super(build_message)
          end

          private

          def build_message
            "Failed to cleanup GitLab databases \n" \
              "Running the following rake task: '#{task}' (from: #{path}) failed:\n" \
              "#{error}"
          end
        end
      end
    end
  end
end
