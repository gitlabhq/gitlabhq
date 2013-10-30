class AddRejectedAndFixedEvents < ActiveRecord::Migration
  # We don't need the forward ("up") data migration
  def down
    # Remove all 'REJECTED' and 'FIXED' events
    # 102 == Event::REJECTED
    # 103 == Event::FIXED
    Event.where(action: [102, 103]).delete_all
  end
end
