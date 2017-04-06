# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class RemoveUniqNameIndexFromNamespace < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    constraint_name = 'namespaces_name_key'

    transaction do
      if index_exists?(:namespaces, :name)
        remove_index(:namespaces, :name)
      end

      # In some bizarre cases PostgreSQL might have a separate unique constraint
      # that we'll need to drop.
      if constraint_exists?(constraint_name) && Gitlab::Database.postgresql?
        execute("ALTER TABLE namespaces DROP CONSTRAINT IF EXISTS #{constraint_name};")
      end
    end
  end

  def down
    unless index_exists?(:namespaces, :name)
      add_concurrent_index(:namespaces, :name, unique: true)
    end
  end

  def constraint_exists?(name)
    indexes(:namespaces).map(&:name).include?(name)
  end
end
