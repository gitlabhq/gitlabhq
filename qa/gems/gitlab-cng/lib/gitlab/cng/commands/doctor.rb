# frozen_string_literal: true

require "tty-which"

module Gitlab
  module Cng
    module Commands
      # Command to check system dependencies
      #
      class Doctor < Command
        TOOLS = {
          "docker" => { required: true },
          "kind" => { required: true },
          "kubectl" => { required: true },
          "helm" => { required: true },
          "tar" => {
            required: false,
            msg: ", tar is optional and only required for providing specific helm chart sha"
          }
        }.freeze

        desc "doctor", "Validate presence of all required system dependencies"
        def doctor
          log "Checking system dependencies", :info, bright: true
          missing_tools = TOOLS.reject do |tool, opts|
            exists = TTY::Which.exist?(tool)
            Helpers::Spinner.spin("Checking if #{tool} is installed", raise_on_error: opts[:required]) do
              raise "#{tool} not found in PATH#{opts[:msg]}" unless exists
            end

            exists
          rescue StandardError
            exists
          end
          return log("All system dependencies are present", :success, bright: true) if missing_tools.empty?

          optional = missing_tools.reject { |_tool, opt| opt[:required] }.keys
          required = missing_tools.keys - optional

          log("Following optional system dependecies are missing: #{optional.join(', ')}", :warn) if optional.any?
          exit_with_error "Following required system dependencies are missing: #{required.join(', ')}" if required.any?
        end
      end
    end
  end
end
