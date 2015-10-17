class AddExceptionsTokenToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :exceptions_token, :string
  end
end
