# frozen_string_literal: true

class Milestone < ApplicationRecord
  include Sortable
  include Timebox
  include Milestoneish
  include FromUnion
  include Importable

  prepend_mod_with('Milestone') # rubocop: disable Cop/InjectEnterpriseEditionModule

  class Predefined
    ALL = [::Timebox::None, ::Timebox::Any, ::Timebox::Started, ::Timebox::Upcoming].freeze
  end

  has_many :milestone_releases
  has_many :releases, through: :milestone_releases

  has_internal_id :iid, scope: :project, track_if: -> { !importing? }
  has_internal_id :iid, scope: :group, track_if: -> { !importing? }

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  scope :active, -> { with_state(:active) }
  scope :started, -> { active.where('milestones.start_date <= CURRENT_DATE') }
  scope :not_started, -> { active.where('milestones.start_date > CURRENT_DATE') }
  scope :not_upcoming, -> do
    active
        .where('milestones.due_date <= CURRENT_DATE')
        .order(:project_id, :group_id, :due_date)
  end

  scope :order_by_name_asc, -> { order(Arel::Nodes::Ascending.new(arel_table[:title].lower)) }
  scope :reorder_by_due_date_asc, -> { reorder(Gitlab::Database.nulls_last_order('due_date', 'ASC')) }
  scope :with_api_entity_associations, -> { preload(project: [:project_feature, :route, namespace: :route]) }
  scope :order_by_dates_and_title, -> { order(due_date: :asc, start_date: :asc, title: :asc) }

  validates_associated :milestone_releases, message: -> (_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }
  validate :uniqueness_of_title, if: :title_changed?

  state_machine :state, initial: :active do
    event :close do
      transition active: :closed
    end

    event :activate do
      transition closed: :active
    end

    state :closed

    state :active
  end

  def self.min_chars_for_partial_matching
    2
  end

  def self.reference_prefix
    '%'
  end

  def self.reference_pattern
    # NOTE: The iid pattern only matches when all characters on the expression
    # are digits, so it will match %2 but not %2.1 because that's probably a
    # milestone name and we want it to be matched as such.
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}
      (?:
        (?<milestone_iid>
          \d+(?!\S\w)\b # Integer-based milestone iid, or
        ) |
        (?<milestone_name>
          [^"\s]+\b |  # String-based single-word milestone title, or
          "[^"]+"      # String-based multi-word milestone surrounded in quotes
        )
      )
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= super("milestones", /(?<milestone>\d+)/)
  end

  def self.upcoming_ids(projects, groups)
    unscoped
      .for_projects_and_groups(projects, groups)
      .active.where('milestones.due_date > CURRENT_DATE')
      .order(:project_id, :group_id, :due_date).select('DISTINCT ON (project_id, group_id) id')
  end

  def self.with_web_entity_associations
    preload(:group, project: [:project_feature, group: [:parent], namespace: :route])
  end

  def participants
    User.joins(assigned_issues: :milestone).where(milestones: { id: id }).distinct
  end

  def self.sort_by_attribute(method)
    sorted =
      case method.to_s
      when 'due_date_asc'
        reorder_by_due_date_asc
      when 'due_date_desc'
        reorder(Gitlab::Database.nulls_last_order('due_date', 'DESC'))
      when 'name_asc'
        reorder(Arel::Nodes::Ascending.new(arel_table[:title].lower))
      when 'name_desc'
        reorder(Arel::Nodes::Descending.new(arel_table[:title].lower))
      when 'start_date_asc'
        reorder(Gitlab::Database.nulls_last_order('start_date', 'ASC'))
      when 'start_date_desc'
        reorder(Gitlab::Database.nulls_last_order('start_date', 'DESC'))
      else
        order_by(method)
      end

    sorted.with_order_id_desc
  end

  def self.sort_with_expired_last(method)
    # NOTE: this is a custom ordering of milestones
    # to prioritize displaying non-expired milestones and milestones without due dates
    sorted = reorder(Arel.sql("(CASE WHEN due_date IS NULL THEN 1 WHEN due_date >= CURRENT_DATE THEN 0 ELSE 2 END) ASC"))
    sorted = if method.to_s == 'expired_last_due_date_desc'
               sorted.order(due_date: :desc)
             else
               sorted.order(due_date: :asc)
             end

    sorted.with_order_id_desc
  end

  def self.states_count(projects, groups = nil)
    return STATE_COUNT_HASH unless projects || groups

    counts = Milestone
               .for_projects_and_groups(projects, groups)
               .reorder(nil)
               .group(:state)
               .count

    {
        opened: counts['active'] || 0,
        closed: counts['closed'] || 0,
        all: counts.values.sum
    }
  end

  def for_display
    self
  end

  def can_be_closed?
    active? && issues.opened.count == 0
  end

  def author_id
    nil
  end

  # TODO: remove after all code paths use `timebox_id`
  # https://gitlab.com/gitlab-org/gitlab/-/issues/215688
  alias_method :milestoneish_id, :timebox_id
  # TODO: remove after all code paths use (group|project)_timebox?
  # https://gitlab.com/gitlab-org/gitlab/-/issues/215690
  alias_method :group_milestone?, :group_timebox?
  alias_method :project_milestone?, :project_timebox?

  def parent
    if group_milestone?
      group
    else
      project
    end
  end

  def subgroup_milestone?
    group_milestone? && parent.subgroup?
  end

  private

  def issues_finder_params
    { project_id: project_id, group_id: group_id, include_subgroups: group_id.present? }.compact
  end

  # milestone titles must be unique across project and group milestones
  def uniqueness_of_title
    if project
      relation = self.class.for_projects_and_groups([project_id], [project.group&.id])
    elsif group
      relation = self.class.for_projects_and_groups(group.projects.select(:id), [group.id])
    end

    title_exists = relation.find_by_title(title)
    errors.add(:title, _("already being used for another group or project %{timebox_name}.") % { timebox_name: timebox_name }) if title_exists
  end
end
