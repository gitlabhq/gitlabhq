# frozen_string_literal: true

class CreateIpRestriction < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ip_restrictions do |t|
      t.references :group, references: :namespace,
                   column: :group_id,
                   type: :integer,
                   null: false,
                   index: true
      t.string :range, null: false # rubocop:disable Migration/PreventStrings
    end

    add_foreign_key(:ip_restrictions, :namespaces, column: :group_id, on_delete: :cascade) # rubocop: disable Migration/AddConcurrentForeignKey
  end
end
