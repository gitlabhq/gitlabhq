# frozen_string_literal: true

class AddNotesIndexOnOrganizationIdSync < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_notes_on_organization_id'

  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_concurrent_index :notes, :organization_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding key is an exception
  end

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
