# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSourceToPagesDomains < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:pages_domains, :certificate_source, :smallint, default: 0) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:pages_domains, :certificate_source)
  end
end
