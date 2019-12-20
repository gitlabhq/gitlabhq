# frozen_string_literal: true
# Group Milestones are milestones that can be shared among many projects within the same group
class GroupMilestone < GlobalMilestone
  include_if_ee('::EE::GroupMilestone') # rubocop: disable Cop/InjectEnterpriseEditionModule
  attr_reader :group, :milestones

  def self.build_collection(group, projects, params)
    params =
      { state: params[:state], search_title: params[:search_title] }

    project_milestones = Milestone.of_projects(projects)
    project_milestones = project_milestones.search_title(params[:search_title]) if params[:search_title].present?
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

  def merge_requests_enabled?
    true
  end
end
