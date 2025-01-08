# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class DatabaseConfigMissingError < StandardError
          attr_reader :filepath

          def initialize(filepath)
            @filepath = filepath
            super(build_message)
          end

          private

          def build_message
            "Database configuration file doesn't exist: #{filepath}"
          end
        end
      end
    end
  end
end
