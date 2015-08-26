class AddAllowFailureToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :allow_failure, :boolean, default: false, null: false
  end
end
