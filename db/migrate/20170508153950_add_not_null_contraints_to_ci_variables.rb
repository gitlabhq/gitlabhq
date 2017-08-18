class AddNotNullContraintsToCiVariables < ActiveRecord::Migration
  DOWNTIME = false

  def up
    change_column(:ci_variables, :key, :string, null: false)
    change_column(:ci_variables, :project_id, :integer, null: false)
  end

  def down
    # no op
  end
end
