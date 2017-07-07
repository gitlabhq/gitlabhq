class RemoveWrongVersionsFromSchemaVersions < ActiveRecord::Migration
  def change
    execute "UPDATE schema_migrations SET version = '20170707183807' WHERE version = '20170723183807'"
    execute "UPDATE schema_migrations SET version = '20170707184243' WHERE version = '20170724184243'"
  end
end
