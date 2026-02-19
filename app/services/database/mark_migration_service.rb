# frozen_string_literal: true

module Database
  class MarkMigrationService < BaseMigrationService
    def initialize(connection:, version:)
      super(connection: connection)
      @version = version
    end

    def execute
      return error(reason: :not_found) unless migration.present?
      return error(reason: :invalid) if executed_versions.include?(migration.version)

      if create_version(version)
        ServiceResponse.success
      else
        error(reason: :invalid)
      end
    end

    private

    attr_reader :version

    def migration
      @migration ||= migration_context
        .migrations
        .find { |migration| migration.version == version }
    end

    def create_version(version)
      im = Arel::InsertManager.new
      im.into(arel_table)
      im.insert(arel_table[:version] => version)
      connection.insert(im, "#{self.class} Create", :version, version)
    end

    def error(reason:)
      ServiceResponse.error(message: 'error', reason: reason)
    end
  end
end
