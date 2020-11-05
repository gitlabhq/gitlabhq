# frozen_string_literal: true

class RenameSitemapNamespace < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  # We're taking over the /sitemap namespace
  # since it's necessary for the default behavior of Sitemaps
  def up
    disable_statement_timeout do
      rename_root_paths(['sitemap'])
    end
  end

  def down
    disable_statement_timeout do
      revert_renames
    end
  end
end
