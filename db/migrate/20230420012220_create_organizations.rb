# frozen_string_literal: true

class CreateOrganizations < Gitlab::Database::Migration[2.1]
  def change
    create_table :organizations do |t|
      t.timestamps_with_timezone null: false
    end
  end
end
