# frozen_string_literal: true
# Global Milestones are milestones that can be shared across multiple projects
class GlobalMilestone
  include Milestoneish
  include_if_ee('::EE::GlobalMilestone') # rubocop: disable Cop/InjectEnterpriseEditionModule

  STATE_COUNT_HASH = { opened: 0, closed: 0, all: 0 }.freeze

  attr_reader :milestone
  alias_attribute :name, :title

  delegate :title, :state, :due_date, :start_date, :participants, :project,
           :group, :expires_at, :closed?, :iid, :group_milestone?, :safe_title,
           :milestoneish_id, :resource_parent, :releases, to: :milestone

  def to_hash
    {
       name: title,
       title: title,
       group_name: group&.full_name,
       project_name: project&.full_name
    }
  end

  def for_display
    @milestone
  end

  def self.build_collection(projects, params)
    items = Milestone.of_projects(projects)
                .reorder_by_due_date_asc
                .order_by_name_asc
    items = items.search_title(params[:search_title]) if params[:search_title].present?

    Milestone.filter_by_state(items, params[:state]).map { |m| new(m) }
  end

  # necessary for legacy milestones
  def self.build(projects, title)
    milestones = Milestone.of_projects(projects).where(title: title)
    return if milestones.blank?

    new(milestones.first)
  end

  def self.states_count(projects, group = nil)
    legacy_group_milestones_count = legacy_group_milestone_states_count(projects)
    group_milestones_count = group_milestones_states_count(group)

    legacy_group_milestones_count.merge(group_milestones_count) do |k, legacy_group_milestones_count, group_milestones_count|
      legacy_group_milestones_count + group_milestones_count
    end
  end

  def self.group_milestones_states_count(group)
    return STATE_COUNT_HASH unless group

    counts_by_state = Milestone.of_groups(group).count_by_state

    {
      opened: counts_by_state['active'] || 0,
      closed: counts_by_state['closed'] || 0,
      all: counts_by_state.values.sum
    }
  end

  def self.legacy_group_milestone_states_count(projects)
    return STATE_COUNT_HASH unless projects

    # We need to reorder(nil) on the projects, because the controller passes them in sorted.
    relation = Milestone.of_projects(projects.reorder(nil)).count_by_state

    {
      opened: relation['active'] || 0,
      closed: relation['closed'] || 0,
      all: relation.values.sum
    }
  end

  def initialize(milestone)
    @milestone = milestone
  end

  def active?
    state == 'active'
  end

  def closed?
    state == 'closed'
  end

  def issues
    @issues ||= Issue.of_milestones(milestone).includes(:project, :assignees, :labels)
  end

  def merge_requests
    @merge_requests ||= MergeRequest.of_milestones(milestone).includes(:target_project, :assignee, :labels)
  end

  def labels
    @labels ||= GlobalLabel.build_collection(milestone.labels).sort_by!(&:title)
  end

  def global_milestone?
    true
  end
end
