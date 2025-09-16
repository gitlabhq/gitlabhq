# frozen_string_literal: true

class AddOrganizationIdToNotes < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :notes, :organization_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Necessary for sharding key
  end
end
