# frozen_string_literal: true

class AddShardsTable < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :shards do |t|
      t.string :name, null: false, index: { unique: true }
    end
  end
end
