# frozen_string_literal: true

module Database
  class ListMigrationsService < BaseMigrationService
    def initialize(connection:, status: 'pending')
      super(connection: connection)
      @status = status
    end

    def execute
      ServiceResponse.success(payload: { migrations: migrations })
    end

    private

    attr_reader :status

    def migrations
      filtered_migrations
        .sort_by(&:version)
        .map { |migration| migration_to_hash(migration) }
    end

    def filtered_migrations
      case status
      when 'pending'
        migration_context.migrations.reject { |m| executed_versions.include?(m.version) }
      when 'executed'
        migration_context.migrations.select { |m| executed_versions.include?(m.version) }
      when 'all'
        migration_context.migrations
      else
        []
      end
    end

    def migration_to_hash(migration)
      {
        version: migration.version.to_i,
        name: migration.name,
        filename: File.basename(migration.filename),
        status: executed_versions.include?(migration.version) ? 'executed' : 'pending'
      }
    end
  end
end
