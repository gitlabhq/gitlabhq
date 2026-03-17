# frozen_string_literal: true

module Database
  class BaseMigrationService
    def initialize(connection:)
      @connection = connection
    end

    private

    attr_reader :connection

    def migration_context
      connection.pool.migration_context
    end

    def executed_versions
      @executed_versions ||= all_executed_migrations.map(&:to_i).to_set
    end

    def all_executed_migrations
      sm = Arel::SelectManager.new(arel_table)
      sm.project(arel_table[:version])
      connection.select_values(sm, "#{self.class} Load")
    end

    def arel_table
      @arel_table ||= Arel::Table.new(:schema_migrations)
    end
  end
end
