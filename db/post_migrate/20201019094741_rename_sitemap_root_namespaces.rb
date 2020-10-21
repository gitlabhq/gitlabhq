# frozen_string_literal: true

class RenameSitemapRootNamespaces < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  # We're taking over the /sitemap.xml and /sitemap.xml.gz namespaces
  # since they're necessary for the default behavior of Sitemaps
  def up
    disable_statement_timeout do
      rename_root_paths(['sitemap.xml', 'sitemap.xml.gz'])
    end
  end

  def down
    disable_statement_timeout do
      revert_renames
    end
  end
end
