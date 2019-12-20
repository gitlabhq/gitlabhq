# frozen_string_literal: true

class AddNameToBadges < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :badges, :name, :string, null: true, limit: 255
  end
end
