class GroupMilestone < ActiveRecord::Base
  include MilestoneModelProperties
  include Milestoneish
  include CacheMarkdownField

  def milestoneish_ids
    id
  end

  def participants
    User.joins(assigned_issues: :group_milestone).where("group_milestones.id = ?", id).uniq
  end

  private

  def issues_finder_conditions
    { group_milestone_id: milestoneish_ids }
  end
end
