class AddExceptionsEnabledToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :exceptions_enabled, :boolean
  end
end
