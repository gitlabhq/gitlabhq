class AddProtectedToCiPipelines < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :ci_pipelines, :protected, :boolean
  end
end
