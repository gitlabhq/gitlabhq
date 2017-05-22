module Gitlab
  module Database
    module Migratable
      extend ActiveSupport::Concern

      NotMigratedError = Class.new(StandardError)

      included do
        after_initialize do
          if self.schema_version.to_i < self.class.latest_schema_version
            raise Migratable::NotMigratedError
          end
        end
      end

      class_methods do
        def migrations
          Hash[@migrations.to_h.sort.reverse]
        end

        def latest_schema_version
          @latest_schema ||= migrations.keys.first
        end

        ##
        # This can be moved to the ActiveRecord::Relation if needed.
        #
        def migrated?(relation)
          relation.where('COALESCE(schema_version, 0) < ?',
                         latest_schema_version).count.zero?
        end

        private

        def migrate(version, migration)
          (@migrations ||= {}).store(version, migration)
        end
      end
    end
  end
end
