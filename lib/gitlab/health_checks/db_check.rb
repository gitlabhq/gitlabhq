# frozen_string_literal: true

module Gitlab
  module HealthChecks
    class DbCheck
      extend SimpleAbstractCheck

      class << self
        private

        def metric_prefix
          'db_ping'
        end

        def successful?(result)
          result == Gitlab::Database.database_base_models.size
        end

        def check
          catch_timeout 10.seconds do
            Gitlab::Database.database_base_models.sum do |_, base|
              base.connection.select_value('SELECT 1')
            end
          end
        end
      end
    end
  end
end
