# frozen_string_literal: true

class AddNullConstraintToTerraformStateName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_column_null :terraform_states, :name, false
  end
end
