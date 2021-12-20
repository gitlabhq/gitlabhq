# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class MigrationObserver
          attr_reader :connection, :observation, :output_dir

          def initialize(observation, output_dir, connection)
            @connection = connection
            @observation = observation
            @output_dir = output_dir
          end

          def before
            # implement in subclass
          end

          def after
            # implement in subclass
          end

          def record
            raise NotImplementedError, 'implement in subclass'
          end
        end
      end
    end
  end
end
