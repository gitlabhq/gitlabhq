# frozen_string_literal: true

class CreateProjectSecurityExclusions < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    create_table :project_security_exclusions do |t|
      t.bigint :project_id, index: true, null: false
      t.timestamps_with_timezone null: false
      t.integer :scanner, limit: 2, null: false
      t.integer :type, limit: 2, null: false
      t.boolean :active, null: false, default: true
      t.text :description, limit: 255
      t.text :value, limit: 255, null: false
    end
  end
end
