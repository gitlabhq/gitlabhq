# frozen_string_literal: true

class InitSchema < Gitlab::Database::Migration[1.0]
  DOWNTIME = false

  def up
    suppress_messages do
      execute(File.read("db/init_structure.sql"))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not able to be reverted."
  end
end
