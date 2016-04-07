class AddPluginToCiBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :plugin, :string
  end
end
