class AddTriggerToBuilds < ActiveRecord::Migration
  def up
    add_column :builds, :trigger_request_id, :integer
  end
end
