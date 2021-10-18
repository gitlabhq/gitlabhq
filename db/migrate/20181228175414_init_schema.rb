# frozen_string_literal: true

class InitSchema < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(IO.read("db/init_structure.sql"))
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
