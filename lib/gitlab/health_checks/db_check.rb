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
          result == '1'
        end

        def check
          catch_timeout 10.seconds do
            if Gitlab::Database.postgresql?
              ActiveRecord::Base.connection.execute('SELECT 1 as ping')&.first&.[]('ping')
            else
              ActiveRecord::Base.connection.execute('SELECT 1 as ping')&.first&.first&.to_s
            end
          end
        end
      end
    end
  end
end
