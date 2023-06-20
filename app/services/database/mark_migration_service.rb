# frozen_string_literal: true

module Database
  class MarkMigrationService
    def initialize(connection:, version:)
      @connection = connection
      @version = version
    end

    def execute
      return error(reason: :not_found) unless migration.present?
      return error(reason: :invalid) if all_versions.include?(migration.version)

      if create_version(version)
        ServiceResponse.success
      else
        error(reason: :invalid)
      end
    end

    private

    attr_reader :connection, :version

    def migration
      @migration ||= connection
        .migration_context
        .migrations
        .find { |migration| migration.version == version }
    end

    def all_versions
      all_executed_migrations.map(&:to_i)
    end

    def all_executed_migrations
      sm = Arel::SelectManager.new(arel_table)
      sm.project(arel_table[:version])
      sm.order(arel_table[:version].asc) # rubocop: disable CodeReuse/ActiveRecord
      connection.select_values(sm, "#{self.class} Load")
    end

    def create_version(version)
      im = Arel::InsertManager.new
      im.into(arel_table)
      im.insert(arel_table[:version] => version)
      connection.insert(im, "#{self.class} Create", :version, version)
    end

    def arel_table
      @arel_table ||= Arel::Table.new(:schema_migrations)
    end

    def error(reason:)
      ServiceResponse.error(message: 'error', reason: reason)
    end
  end
end
