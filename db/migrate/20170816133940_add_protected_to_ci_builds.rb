class AddProtectedToCiBuilds < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column :ci_builds, :protected, :boolean
  end
end
