# frozen_string_literal: true

module Gitlab
  module Database
    module HealthStatus
      class Context
        attr_reader :status_checker, :connection, :tables

        # status_checker: the caller object which checks for database health status
        #                 eg: BackgroundMigration::BatchedMigration or DeferJobs::DatabaseHealthStatusChecker
        def initialize(status_checker, connection, tables)
          @status_checker = status_checker
          @connection = connection
          @tables = tables
        end

        def status_checker_info
          {
            status_checker_id: status_checker.id,
            status_checker_type: status_checker.class.name,
            job_class_name: status_checker.job_class_name
          }
        end
      end
    end
  end
end
