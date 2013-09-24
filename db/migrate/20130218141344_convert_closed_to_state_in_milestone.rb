class ConvertClosedToStateInMilestone < ActiveRecord::Migration
  def up
    Milestone.transaction do
      Milestone.where(closed: true).update_all(state: :closed)
      Milestone.where(closed: false).update_all(state: :active)
    end
  end

  def down
    Milestone.transaction do
      Milestone.where(state: :closed).update_all(closed: true)
    end
  end
end
