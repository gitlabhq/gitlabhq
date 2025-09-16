# frozen_string_literal: true

class AsyncIndexNotesOnOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  INDEX_NAME = 'index_notes_on_organization_id'

  def up
    prepare_async_index :notes, :organization_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Necessary for sharding key
  end

  def down
    unprepare_async_index :notes, :organization_id, name: INDEX_NAME
  end
end
