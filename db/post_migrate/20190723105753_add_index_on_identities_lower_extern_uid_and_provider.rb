# frozen_string_literal: true

class AddIndexOnIdentitiesLowerExternUidAndProvider < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = "index_on_identities_lower_extern_uid_and_provider"

  def up
    add_concurrent_index(:identities, 'lower(extern_uid), provider', name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:identities, INDEX_NAME)
  end
end
