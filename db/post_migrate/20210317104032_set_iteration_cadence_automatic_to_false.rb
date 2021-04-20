# frozen_string_literal: true

class SetIterationCadenceAutomaticToFalse < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE iterations_cadences
      SET automatic = FALSE
      WHERE iterations_cadences.automatic = TRUE
    SQL
  end

  def down
    #  no-op
  end
end
