# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class MigrationObserver
          attr_reader :connection, :observation

          def initialize(observation)
            @connection = ActiveRecord::Base.connection
            @observation = observation
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
