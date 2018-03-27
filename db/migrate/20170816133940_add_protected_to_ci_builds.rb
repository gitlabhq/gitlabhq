class AddProtectedToCiBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :ci_builds, :protected, :boolean
  end
end
