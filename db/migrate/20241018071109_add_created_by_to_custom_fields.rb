# frozen_string_literal: true

class AddCreatedByToCustomFields < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_reference :custom_fields, :created_by, index: true, foreign_key: { on_delete: :nullify, to_table: :users } # rubocop:disable Migration/AddReference -- table is empty
  end
end
