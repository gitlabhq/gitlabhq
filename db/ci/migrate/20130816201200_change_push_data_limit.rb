class ChangePushDataLimit < ActiveRecord::Migration
  def change
    change_column :builds, :push_data, :text, :limit => 16777215
  end
end
