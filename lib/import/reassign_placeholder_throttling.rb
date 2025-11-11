# frozen_string_literal: true

module Import
  class ReassignPlaceholderThrottling
    DATABASE_TABLE_HEALTH_INDICATORS = [Gitlab::Database::HealthStatus::Indicators::AutovacuumActiveOnTable].freeze
    GLOBAL_DATABASE_HEALTH_INDICATORS = [
      Gitlab::Database::HealthStatus::Indicators::WriteAheadLog,
      Gitlab::Database::HealthStatus::Indicators::PatroniApdex
    ].freeze

    DatabaseHealthStatusChecker = Struct.new(:id, :job_class_name)
    DatabaseHealthError = Class.new(StandardError)

    def initialize(import_source_user)
      @import_source_user = import_source_user
      @reassigned_by_user = import_source_user.reassigned_by_user
      @unavailable_tables = []
    end

    # The `#db_table_unavailable?` check is behind a feature flag that we intend not to roll out.
    # The flag is a conservative measure to allow us to enable it IF it's determined that we should
    # be delaying reassignments when tables are being autovacuumed.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/525566#note_2418809939.
    #
    # TODO Remove the following block of code, and all related code (`unavailable_tables`,
    # `#db_table_unavailable?`, and `DATABASE_TABLE_HEALTH_INDICATORS`) as part of
    # https://gitlab.com/gitlab-org/gitlab/-/issues/534613
    #
    # If table health check fails, skip processing this relation
    # and move on to the next one. We later raise a `DatabaseHealthError` to
    # reschedule the reassignment where the skipped relations can be tried again.
    def db_table_unavailable?(model_relation)
      return false if Feature.disabled?(:reassignment_throttling, reassigned_by_user)
      return false if Feature.disabled?(:reassignment_throttling_table_check, reassigned_by_user)
      return false unless autovacuum_active?(model_relation)

      unavailable_tables << model_relation.table_name
      true
    end

    def db_health_check!
      return if Feature.disabled?(:reassignment_throttling, reassigned_by_user)

      stop_signal = Rails.cache.fetch("reassign_placeholder_user_records_service_db_check", expires_in: 30.seconds) do
        gitlab_schema = :gitlab_main

        health_context = Gitlab::Database::HealthStatus::Context.new(
          DatabaseHealthStatusChecker.new(import_source_user.id, self.class.name),
          schema_connection(gitlab_schema),
          []
        )

        Gitlab::Database::HealthStatus.evaluate(health_context, GLOBAL_DATABASE_HEALTH_INDICATORS).any?(&:stop?)
      end

      raise DatabaseHealthError, "Database unhealthy" if stop_signal
    end

    def unavailable_tables?
      unavailable_tables.any?
    end

    private

    attr_reader :import_source_user, :reassigned_by_user, :unavailable_tables

    def autovacuum_active?(model)
      health_context = Gitlab::Database::HealthStatus::Context.new(
        DatabaseHealthStatusChecker.new(import_source_user.id, self.class.name),
        model_connection(model),
        [model.table_name]
      )

      Gitlab::Database::HealthStatus.evaluate(health_context, DATABASE_TABLE_HEALTH_INDICATORS).any?(&:stop?)
    end

    def model_connection(model)
      schema = Gitlab::Database::GitlabSchema.tables_to_schema[model.table_name]

      schema_connection(schema)
    end

    def schema_connection(schema)
      Gitlab::Database.schemas_to_base_models[schema].first.connection
    end
  end
end
