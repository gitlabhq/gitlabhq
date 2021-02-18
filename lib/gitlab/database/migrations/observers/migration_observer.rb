# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class MigrationObserver
          attr_reader :connection

          def initialize
            @connection = ActiveRecord::Base.connection
          end

          def before
            # implement in subclass
          end

          def after
            # implement in subclass
          end

          def record(observation)
            raise NotImplementedError, 'implement in subclass'
          end
        end
      end
    end
  end
end
