# frozen_string_literal: true
# Group Milestones are milestones that can be shared among many projects within the same group
class GroupMilestone < GlobalMilestone
  attr_reader :group, :milestones

  def self.build_collection(group, projects, params)
    params =
      { state: params[:state] }

    project_milestones = Milestone.of_projects(projects)
    child_milestones = Milestone.filter_by_state(project_milestones, params[:state])
    grouped_milestones = child_milestones.group_by(&:title)

    grouped_milestones.map do |title, grouped|
      new(title, grouped, group)
    end
  end

  def self.build(group, projects, title)
    child_milestones = Milestone.of_projects(projects).where(title: title)
    return if child_milestones.blank?

    new(title, child_milestones, group)
  end

  def initialize(title, milestones, group)
    @milestones = milestones
    @group = group
  end

  def milestone
    @milestone ||= milestones.find { |m| m.description.present? } || milestones.first
  end

  def issues_finder_params
    { group_id: group.id }
  end

  def legacy_group_milestone?
    true
  end
end
