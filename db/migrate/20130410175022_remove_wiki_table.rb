# rubocop:disable all
class RemoveWikiTable < ActiveRecord::Migration[4.2]
  def up
    drop_table :wikis
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
