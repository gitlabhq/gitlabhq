# rubocop:disable all
class AddMissingIndex < ActiveRecord::Migration[4.2]
  def change
    add_index "services", [:created_at, :id]
  end
end
