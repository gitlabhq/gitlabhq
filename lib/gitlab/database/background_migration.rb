module Gitlab
  module Database
    ##
    # Abstract base class for background migrations.
    #
    class BackgroundMigration
      include ActiveRecord::ConnectionAdapters::DatabaseStatements

      def self.perform(id, version, model)
        new(id, version, model).tap do |migration|
          break if migration.done?

          migration.perform!
          migration.bump!
        end
      end

      def initialize(id, version, model)
        @id = id
        @version = version
        @model = model
      end

      def done?
        @model.where('id = ? AND COALESCE(schema_version, 0) < ?',
                       @id, @version).count.zero?
      end

      def bump!
        @model.where(id: @id).update_all(schema_version: @version)
      end

      def perform!
        raise NotImplementedError
      end
    end
  end
end

