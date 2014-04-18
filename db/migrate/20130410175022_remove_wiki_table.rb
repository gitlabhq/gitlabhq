class RemoveWikiTable < ActiveRecord::Migration
  def up
    drop_table :wikis
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
