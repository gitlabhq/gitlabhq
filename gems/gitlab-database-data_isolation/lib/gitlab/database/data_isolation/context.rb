# frozen_string_literal: true

module Gitlab
  module Database
    module DataIsolation
      module Context
        THREAD_KEY = :gitlab_database_data_isolation_disabled

        class << self
          def disable!
            Thread.current[THREAD_KEY] = true
          end

          def enable!
            Thread.current[THREAD_KEY] = false
          end

          def disabled?
            Thread.current[THREAD_KEY] == true
          end

          def without_data_isolation
            previous = disabled?
            disable!
            yield
          ensure
            Thread.current[THREAD_KEY] = previous
          end
        end
      end
    end
  end
end
