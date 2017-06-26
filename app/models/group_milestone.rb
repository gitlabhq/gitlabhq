class GroupMilestone < ActiveRecord::Base
  include SharedMilestoneProperties
  include Milestoneish
  include CacheMarkdownField

  belongs_to :group

  class << self
    # Build legacy group milestone which consists on all project milestones
    # with the same title.
    def build(group, projects, title)
      GlobalMilestone.build(projects, title).tap do |milestone|
        milestone&.group = group
      end
    end
  end

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
