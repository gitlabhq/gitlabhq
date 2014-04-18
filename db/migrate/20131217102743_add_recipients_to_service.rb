class AddRecipientsToService < ActiveRecord::Migration
  def change
    add_column :services, :recipients, :text
  end
end
