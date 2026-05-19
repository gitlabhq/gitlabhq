# frozen_string_literal: true

# gitlab-database-data_isolation opens the Gitlab::Database namespace during
# Bundler.require, which prevents Zeitwerk from autoloading lib/gitlab/database.rb.
# This initializer explicitly loads the file so that subsequent initializers
# (e.g. 0_migration_paths_additional.rb) find all expected methods on the module.
require Rails.root.join('lib/gitlab/database')
