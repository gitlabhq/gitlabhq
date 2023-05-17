# frozen_string_literal: true

class EnsurePackagesNpmMetadataCachesIsEmpty < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    truncate_tables!('packages_npm_metadata_caches')
  end

  def down
    # no-op
  end
end
