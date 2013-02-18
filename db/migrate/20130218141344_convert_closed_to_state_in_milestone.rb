class ConvertClosedToStateInMilestone < ActiveRecord::Migration
  def up
    Milestone.transaction do
      Milestone.find_each do |milestone|
        milestone.state = milestone.closed? ? :closed : :active
        milestone.save
      end
    end
  end

  def down
    Milestone.transaction do
      Milestone.find_each do |milestone|
        milestone.closed = milestone.closed?
        milestone.save
      end
    end
  end
end
