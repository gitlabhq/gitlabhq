# frozen_string_literal: true

# The patch to load_migration rolls back to Rails 6.1 behavior:
#
# https://github.com/rails/rails/blob/v6.1.4.3/activerecord/lib/active_record/migration.rb#L1044
#
# It fixes the tests that relies on the fact that the same constants have the same object_id.
# For example to make sure that stub_const works correctly.
#
# It overrides the new behavior that removes the constant first:
#
# https://github.com/rails/rails/blob/v7.1.3.4/activerecord/lib/active_record/migration.rb#L1186

# The following is a reminder for when we upgrade to Rails 7.2. In particular,
# we need to pay special attention to ensure that our ActiveRecord overrides are
# compatible.

if ::ActiveRecord::VERSION::STRING >= "7.2"
  raise 'New version of active-record detected, please remove or update this patch'
end

module Gitlab
  module Database
    module Migrations
      module MigrationOrderMixin
        module MigrationProxyOverrides
          def version
            migration.version
          end

          def milestone
            migration.try(:milestone)
          end

          private

          def load_migration
            require(File.expand_path(filename))

            name.constantize.new(name, self[:version])
          end
        end

        module MigratorOverrides
          def current_version
            reverse_sorted_migrations
              .find { |m| migrated.include?(m.version) }
              .try(:version) || 0
          end

          private

          def reverse_sorted_migrations
            @reverse_sorted_migrations ||= migrations.sort_by(&:version).reverse
          end
        end

        def self.patch!
          ActiveRecord::MigrationProxy.prepend(MigrationProxyOverrides)
          ActiveRecord::Migrator.prepend(MigratorOverrides)
        end
      end
    end
  end
end
