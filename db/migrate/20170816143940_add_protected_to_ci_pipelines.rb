class AddProtectedToCiPipelines < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_pipelines, :protected, :boolean
  end
end
