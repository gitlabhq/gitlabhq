module Gitlab
  module Database
    module Migratable
      extend ActiveSupport::Concern

      NotMigratedError = Class.new(StandardError)

      included do
        after_initialize do |record|
          if record.new_record?
            self.schema_version = self.class.latest_schema_version
          end

          if self.schema_version.to_i < self.class.latest_schema_version
            raise Migratable::NotMigratedError
          end
        end
      end

      class_methods do
        def migrations(min_version = nil)
          Hash[@migrations.to_h.sort].tap do |migrations|
            if min_version.present?
              return migrations.select { |key| key > min_version }
            end
          end
        end

        def latest_schema_version
          @latest_schema ||= migrations.keys.last
        end

        ##
        # This is designed to operate on an ActiveRecord::Relation scope extension.
        #
        def migrated?
          all.where('COALESCE(schema_version, 0) < ?',
                    latest_schema_version).count.zero?
        end

        ##
        # PoC, needs some performance improvements.
        #
        # Behaves like an ActiveRecord::Relation scope extension.
        #
        # Batch size can be configurable.
        #
        def migrate!
          all.in_batches(of: 1000) do |relation|
            ResourceBackgroundMigrationWorker
              .perform_async(self.name, relation.pluck(:id, :schema_version))
          end
        end

        private

        def migrate(version, migration)
          (@migrations ||= {}).store(version, migration)
        end
      end
    end
  end
end
