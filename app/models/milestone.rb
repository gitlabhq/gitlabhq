# frozen_string_literal: true

class Milestone < ApplicationRecord
  # Represents a "No Milestone" state used for filtering Issues and Merge
  # Requests that have no milestone assigned.
  MilestoneStruct = Struct.new(:title, :name, :id) do
    # Ensure these models match the interface required for exporting
    def serializable_hash(_opts = {})
      { title: title, name: name, id: id }
    end
  end

  None = MilestoneStruct.new('No Milestone', 'No Milestone', 0)
  Any = MilestoneStruct.new('Any Milestone', '', -1)
  Upcoming = MilestoneStruct.new('Upcoming', '#upcoming', -2)
  Started = MilestoneStruct.new('Started', '#started', -3)

  include Sortable
  include Referable
  include Timebox
  include Milestoneish
  include FromUnion
  include Importable
  include Gitlab::SQL::Pattern

  prepend_if_ee('::EE::Milestone') # rubocop: disable Cop/InjectEnterpriseEditionModule

  has_many :milestone_releases
  has_many :releases, through: :milestone_releases

  has_internal_id :iid, scope: :project, track_if: -> { !importing? }, init: ->(s) { s&.project&.milestones&.maximum(:iid) }
  has_internal_id :iid, scope: :group, track_if: -> { !importing? }, init: ->(s) { s&.group&.milestones&.maximum(:iid) }

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  scope :started, -> { active.where('milestones.start_date <= CURRENT_DATE') }

  scope :order_by_name_asc, -> { order(Arel::Nodes::Ascending.new(arel_table[:title].lower)) }
  scope :reorder_by_due_date_asc, -> { reorder(Gitlab::Database.nulls_last_order('due_date', 'ASC')) }

  validates_associated :milestone_releases, message: -> (_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }

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

  class << self
    # Searches for milestones with a matching title or description.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      fuzzy_search(query, [:title, :description])
    end

    # Searches for milestones with a matching title.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search_title(query)
      fuzzy_search(query, [:title])
    end

    def filter_by_state(milestones, state)
      case state
      when 'closed' then milestones.closed
      when 'all' then milestones
      else milestones.active
      end
    end

    def count_by_state
      reorder(nil).group(:state).count
    end

    def predefined_id?(id)
      [Any.id, None.id, Upcoming.id, Started.id].include?(id)
    end

    def predefined?(milestone)
      predefined_id?(milestone&.id)
    end
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

  def participants
    User.joins(assigned_issues: :milestone).where("milestones.id = ?", id).distinct
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

  ##
  # Returns the String necessary to reference a Milestone in Markdown. Group
  # milestones only support name references, and do not support cross-project
  # references.
  #
  # format - Symbol format to use (default: :iid, optional: :name)
  #
  # Examples:
  #
  #   Milestone.first.to_reference                           # => "%1"
  #   Milestone.first.to_reference(format: :name)            # => "%\"goal\""
  #   Milestone.first.to_reference(cross_namespace_project)  # => "gitlab-org/gitlab-foss%1"
  #   Milestone.first.to_reference(same_namespace_project)   # => "gitlab-foss%1"
  #
  def to_reference(from = nil, format: :name, full: false)
    format_reference = milestone_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if project
      "#{project.to_reference_base(from, full: full)}#{reference}"
    else
      reference
    end
  end

  def reference_link_text(from = nil)
    self.class.reference_prefix + self.title
  end

  def for_display
    self
  end

  def can_be_closed?
    active? && issues.opened.count.zero?
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

  private

  def milestone_format_reference(format = :iid)
    raise ArgumentError, _('Unknown format') unless [:iid, :name].include?(format)

    if group_milestone? && format == :iid
      raise ArgumentError, _('Cannot refer to a group milestone by an internal id!')
    end

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      iid
    end
  end

  def issues_finder_params
    { project_id: project_id, group_id: group_id, include_subgroups: group_id.present? }.compact
  end
end
