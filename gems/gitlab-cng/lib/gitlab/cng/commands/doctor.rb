# frozen_string_literal: true

require "tty-which"

module Gitlab
  module Cng
    module Commands
      # Command to check system dependencies
      #
      class Doctor < Command
        TOOLS = %w[docker kind kubectl helm].freeze

        desc "doctor", "Validate presence of all required system dependencies"
        def doctor
          log "Checking system dependencies", :info, bright: true
          missing_tools = TOOLS.filter_map do |tool|
            Helpers::Spinner.spin("Checking if #{tool} is installed") do
              raise "#{tool} not found in PATH" unless TTY::Which.exist?(tool)
            end
          rescue StandardError
            tool
          end
          return log "All system dependencies are present", :success, bright: true if missing_tools.empty?

          exit_with_error "The following system dependencies are missing: #{missing_tools.join(', ')}"
        end
      end
    end
  end
end
