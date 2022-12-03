# frozen_string_literal: true

class DropExperimentsTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    drop_table :experiments, if_exists: true
  end

  def down
    unless table_exists?(:experiments)
      create_table :experiments do |t| # rubocop:disable Migration/SchemaAdditionMethodsNoPost
        t.text :name, null: false

        t.index :name, unique: true
      end
    end

    add_text_limit :experiments, :name, 255
  end
end
