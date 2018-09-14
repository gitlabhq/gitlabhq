# frozen_string_literal: true
# Dashboard Group Milestones are milestones that allow us to pull more info out for the UI that the Milestone object doesn't allow for
class DashboardGroupMilestone < GlobalMilestone
  extend ::Gitlab::Utils::Override

  attr_reader :group_name

  override :initialize
  def initialize(milestone)
    super(milestone.title, Array(milestone))

    @group_name = milestone.group.full_name
  end

  def self.build_collection(groups)
    MilestonesFinder.new(group_ids: groups.select(:id)).execute.map { |m| new(m) } # rubocop: disable CodeReuse/Finder
  end

  override :group_milestone?
  def group_milestone?
    @first_milestone.group_milestone?
  end

  override :milestoneish_ids
  def milestoneish_ids
    milestones.map(&:id)
  end

  def group
    @first_milestone.group
  end

  def iid
    @first_milestone.iid
  end
end
