# frozen_string_literal: true

class AddShardsTable < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :shards do |t|
      t.string :name, null: false, index: { unique: true } # rubocop:disable Migration/PreventStrings
    end
  end
end
