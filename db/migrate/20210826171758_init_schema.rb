# frozen_string_literal: true

class InitSchema < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(File.read("db/init_structure.sql"))
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not able to be reverted."
  end
end
