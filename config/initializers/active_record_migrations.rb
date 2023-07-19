# frozen_string_literal: true

Gitlab::Database::Migrations::LockRetryMixin.patch!
Gitlab::Database::Migrations::PgBackendPid.patch!
Gitlab::Database::Migrations::RunnerBackoff::ActiveRecordMixin.patch!

# This patch rolls back to Rails 6.1 behavior:
#
# https://github.com/rails/rails/blob/v6.1.4.3/activerecord/lib/active_record/migration.rb#L1044
#
# It fixes the tests that relies on the fact that the same constants have the same object_id.
# For example to make sure that stub_const works correctly.
#
# It overrides the new behavior that removes the constant first:
#
# https://github.com/rails/rails/blob/v7.0.5/activerecord/lib/active_record/migration.rb#L1054
module ActiveRecord
  class MigrationProxy
    private

    def load_migration
      require(File.expand_path(filename))
      name.constantize.new(name, version)
    end
  end
end
