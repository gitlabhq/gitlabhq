class TouchProjectsLastActivity < ActiveRecord::Migration
  def up
    Project.record_timestamps = false

    Project.find_each do |project|
      last_event = project.events.order(:created_at).last
      if last_event and last_event.created_at > project.updated_at
        project.update_attribute(:updated_at, last_event.created_at)
      end
    end

    Project.record_timestamps = true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
