# frozen_string_literal: true

class CreateExperiment < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:experiments)
      create_table :experiments do |t|
        t.text :name, null: false

        t.index :name, unique: true
      end
    end

    add_text_limit :experiments, :name, 255
  end

  def down
    drop_table :experiments
  end
end
