# frozen_string_literal: true

# Backport of https://github.com/rails/rails/pull/54853
# Fixed in Rails 8.1.0
#
# Problem:
# Running `db:schema:load:<n>` (e.g., `db:schema:load:main`) fails with:
#   TypeError: Invalid type for configuration. Expected Symbol, String, or Hash. Got nil
#
# This occurs because `db:schema:load:<n>` has a prerequisite on `db:test:purge:<n>`,
# which fails when no test database is configured in database.yml.
#
# The fix removes the `db:test:purge:<n>` prerequisite. Rails maintains the test
# schema lazily when tests run via `ActiveRecord::Migration.maintain_test_schema!`.
#
# See: https://github.com/rails/rails/issues/50672
#
# TODO: Remove this file after upgrading to Rails >= 8.1.0

if Gem::Version.new(Rails::VERSION::STRING) >= Gem::Version.new('8.1.0')
  raise 'Remove this patch after upgrading to Rails 8.1.0+'
end

%w[main ci sec].each do |db_name|
  schema_load_task_name = "db:schema:load:#{db_name}"
  test_purge_task_name = "db:test:purge:#{db_name}"

  next unless Rake::Task.task_defined?(schema_load_task_name)

  Rake::Task[schema_load_task_name].prerequisites.delete(test_purge_task_name)
end
