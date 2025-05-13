# frozen_string_literal: true

module Database
  class BatchedBackgroundMigrationsFinder
    RETURNED_MIGRATIONS = 20

    def initialize(params:)
      @params = params
    end

    def execute
      raise ArgumentError, 'database parameter is required' if params[:database].blank?

      return batched_migration_class.none unless Gitlab::Database.has_config?(database_name)

      @migrations = migrations

      filter_by_job_class_name

      @migrations.limit(RETURNED_MIGRATIONS)
    end

    private

    attr_reader :params

    def migrations
      batched_migration_class
        .ordered_by_created_at_desc
        .for_gitlab_schema(schema)
    end

    def filter_by_job_class_name
      return unless params[:job_class_name].present?

      @migrations = @migrations.for_job_class(params[:job_class_name])
    end

    def batched_migration_class
      Gitlab::Database::BackgroundMigration::BatchedMigration
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
