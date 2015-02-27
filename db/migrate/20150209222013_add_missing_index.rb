class AddMissingIndex < ActiveRecord::Migration
  def change
    add_index "services", [:created_at, :id]
  end
end
