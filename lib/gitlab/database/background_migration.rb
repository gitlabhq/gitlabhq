module Gitlab
  module Database
    ##
    # Abstract base class for background migrations.
    #
    class BackgroundMigration
      def self.perform(id, version, resource)
        new(id, version, resource).tap do |migration|
          break if migration.done?

          migration.perform!
          migration.bump!
        end
      end

      def initialize(id, version, resource)
        @id = id
        @version = version
        @resource = resource
      end

      def done?
        resource.where('id = ? AND COALESCE(schema_version, 0) < ?',
                       @id, @version).count.zero?
      end

      def bump!
        resource.where(id: 1).update_all(schema_version: @version)
      end

      def perform!
        raise NotImplementedError
      end
    end
  end
end

