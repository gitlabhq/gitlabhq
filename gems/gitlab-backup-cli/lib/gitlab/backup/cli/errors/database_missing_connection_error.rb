# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Errors
        class DatabaseMissingConnectionError < StandardError
          def initialize(connection_name)
            @connection_name = connection_name
            super(build_message)
          end

          private

          def build_message
            "Database connection for #{@connection_name} is missing"
          end
        end
      end
    end
  end
end
