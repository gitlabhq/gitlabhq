class AddContactedAtToRunner < ActiveRecord::Migration
  def change
    add_column :runners, :contacted_at, :datetime, null: true
  end
end
