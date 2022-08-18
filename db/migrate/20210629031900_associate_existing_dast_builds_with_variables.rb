# frozen_string_literal: true

class AssociateExistingDastBuildsWithVariables < ActiveRecord::Migration[6.1]
  def up
    # no-op: Must have run before %"15.X" as it is not compatible with decomposed CI database
  end

  def down
    # No-op
  end
end
