# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      class Context
        attr_reader :status_checker, :connection, :tables, :gitlab_schema

        # status_checker: the caller object which checks for database health status
        #                 eg: batched_migration
        def initialize(status_checker, connection, tables, gitlab_schema)
          @status_checker = status_checker
          @connection = connection
          @tables = tables
          @gitlab_schema = gitlab_schema
        end

        def status_checker_info
          data = {
            status_checker_id: status_checker.id,
            status_checker_type: status_checker.class.name
          }

          if status_checker.is_a?(Gitlab::Database::BackgroundMigration::BatchedMigration)
            data[:job_class_name] = status_checker.job_class_name
          end

          data
        end
      end
    end
  end
end
