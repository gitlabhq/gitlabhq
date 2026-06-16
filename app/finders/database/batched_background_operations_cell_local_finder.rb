# frozen_string_literal: true

module Database
  class BatchedBackgroundOperationsCellLocalFinder
    RETURNED_OPERATIONS = 20

    def initialize(params:)
      @params = params
    end

    def execute
      raise ArgumentError, 'database parameter is required' if params[:database].blank?

      return worker_class.none unless Gitlab::Database.has_config?(database_name)

      relation.limit(RETURNED_OPERATIONS)
    end

    private

    attr_reader :params

    def relation
      r = worker_class
        .for_gitlab_schema(schema)
        .ordered_by_created_at_desc

      params[:job_class_name].present? ? r.for_job_class(params[:job_class_name]) : r
    end

    def worker_class
      Gitlab::Database::BackgroundOperation::WorkerCellLocal
    end

    def schema
      Gitlab::Database.gitlab_schemas_for_connection(base_model.connection)
    end

    def base_model
      Gitlab::Database.database_base_models[database_name]
    end

    def database_name
      params[:database]
    end
  end
end
