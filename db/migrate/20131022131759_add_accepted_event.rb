class AddAcceptedEvent < ActiveRecord::Migration
  # We don't need the forward ("up") data migration
  def down
    # Remove all 'ACCEPTED' events
    # 101 == Event::ACCEPTED, but I'm not sure whether that constant is supposed to be available when db:rollback is executed
    Event.where(action: 101).delete_all
  end
end
