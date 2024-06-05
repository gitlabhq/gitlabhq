# frozen_string_literal: true

class Milestone < ApplicationRecord
  include AtomicInternalId
  include Sortable
  include Timebox
  include Milestoneish
  include FromUnion
  include Importable
  include IidRoutes
  include UpdatedAtFilterable
  include EachBatch
  include Spammable
  include AfterCommitQueue

  prepend_mod_with('Milestone') # rubocop: disable Cop/InjectEnterpriseEditionModule

  class Predefined
    ALL = [::Timebox::None, ::Timebox::Any, ::Timebox::Started, ::Timebox::Upcoming].freeze
  end

  belongs_to :project
  belongs_to :group

  has_many :milestone_releases
  has_many :releases, through: :milestone_releases

  has_internal_id :iid, scope: :project, track_if: -> { !importing? }
  has_internal_id :iid, scope: :group, track_if: -> { !importing? }

  has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

  scope :by_iid, ->(iid) { where(iid: iid) }
  scope :active, -> { with_state(:active) }
  scope :started, -> { active.where('milestones.start_date <= CURRENT_DATE') }
  scope :not_started, -> { active.where('milestones.start_date > CURRENT_DATE') }
  scope :not_upcoming, -> do
    active
        .where('milestones.due_date <= CURRENT_DATE')
        .order(:project_id, :group_id, :due_date)
  end

  scope :of_projects, ->(ids) { where(project_id: ids) }
  scope :for_projects, -> { where(group: nil).includes(:project) }
  scope :for_projects_and_groups, ->(projects, groups) do
    projects = projects.compact if projects.is_a? Array
    projects = [] if projects.nil?

    groups = groups.compact if groups.is_a? Array
    groups = [] if groups.nil?

    from_union([where(project_id: projects), where(group_id: groups)], remove_duplicates: false)
  end

  scope :order_by_name_asc, -> { order(Arel::Nodes::Ascending.new(arel_table[:title].lower)) }
  scope :reorder_by_due_date_asc, -> { reorder(arel_table[:due_date].asc.nulls_last) }
  scope :with_api_entity_associations, -> { preload(project: [:project_feature, :route, { namespace: :route }]) }
  scope :preload_for_indexing, -> { includes(project: [:project_feature]) }
  scope :order_by_dates_and_title, -> { order(due_date: :asc, start_date: :asc, title: :asc) }
  scope :with_ids_or_title, ->(ids:, title:) { id_in(ids).or(with_title(title)) }

  validates :group, presence: true, unless: :project
  validates :project, presence: true, unless: :group
  validates :title, presence: true
  validates_associated :milestone_releases, message: ->(_, obj) { obj[:value].map(&:errors).map(&:full_messages).join(",") }
  validate :parent_type_check
  validate :uniqueness_of_title, if: :title_changed?

  attr_spammable :title, spam_title: true
  attr_spammable :description, spam_description: true

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

  # Searches for timeboxes with a matching title.
  #
  # This method uses ILIKE on PostgreSQL
  #
  # query - The search query as a String
  #
  # Returns an ActiveRecord::Relation.
  def self.search_title(query)
    fuzzy_search(query, [:title])
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
          [^"\s\<]+\b |  # String-based single-word milestone title, or
          "[^"]+"      # String-based multi-word milestone surrounded in quotes
        )
      )
    }x
  end

  def self.link_reference_pattern
    @link_reference_pattern ||= compose_link_reference_pattern('milestones', /(?<milestone>\d+)/)
  end

  def self.upcoming_ids(projects, groups)
    unscoped
      .for_projects_and_groups(projects, groups)
      .active.where('milestones.due_date > CURRENT_DATE')
      .order(:project_id, :group_id, :due_date).select('DISTINCT ON (project_id, group_id) id')
  end

  def self.with_web_entity_associations
    preload(:group, project: [:project_feature, { group: [:parent], namespace: :route }])
  end

  def participants
    User.joins(assigned_issues: :milestone)
      .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422155')
      .where(milestones: { id: id }).distinct
  end

  def self.sort_by_attribute(method)
    sorted =
      case method.to_s
      when 'due_date_asc'
        reorder_by_due_date_asc
      when 'due_date_desc'
        reorder(arel_table[:due_date].desc.nulls_last)
      when 'name_asc'
        reorder(Arel::Nodes::Ascending.new(arel_table[:title].lower))
      when 'name_desc'
        reorder(Arel::Nodes::Descending.new(arel_table[:title].lower))
      when 'start_date_asc'
        reorder(arel_table[:start_date].asc.nulls_last)
      when 'start_date_desc'
        reorder(arel_table[:start_date].desc.nulls_last)
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

  def group_milestone?
    group_id.present?
  end

  def project_milestone?
    project_id.present?
  end

  def resource_parent
    group || project
  end

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

  def merge_requests_enabled?
    if group_milestone?
      # Assume that groups have at least one project with merge requests enabled.
      # Otherwise, we would need to load all of the projects from the database.
      true
    elsif project_milestone?
      project&.merge_requests_enabled?
    end
  end

  ##
  # Returns the String necessary to reference a milestone in Markdown. Group
  # milestones only support name references, and do not support cross-project
  # references.
  #
  # format - Symbol format to use (default: :iid, optional: :name)
  #
  # Examples:
  #
  #   Milestone.first.to_reference                           # => "%1"
  #   Milestone.first.to_reference(cross_namespace_project)  # => "gitlab-org/gitlab-foss%1"
  #   Milestone.first
  #     .to_reference(project, full: true, absolute_path: true) # => "/gitlab-org/gitlab-foss%1"
  #
  def to_reference(from = nil, format: :name, full: false, absolute_path: false)
    format_reference = timebox_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if project
      "#{project.to_reference_base(from, full: full, absolute_path: absolute_path)}#{reference}"
    else
      "#{group.to_reference_base(from, full: full, absolute_path: absolute_path)}#{reference}"
    end
  end

  def check_for_spam?(*)
    spammable_attribute_changed? && parent.public?
  end

  private

  def timebox_format_reference(format = :iid)
    raise ArgumentError, _('Unknown format') unless [:iid, :name].include?(format)

    if group_milestone? && format == :iid
      raise ArgumentError, _('Cannot refer to a group milestone by an internal id!')
    end

    if format == :name && name.exclude?('"')
      %("#{name}")
    else
      iid
    end
  end

  # Milestone should be either a project milestone or a group milestone
  def parent_type_check
    return unless group_id && project_id

    field = project_id_changed? ? :project_id : :group_id
    errors.add(field, _("milestone should belong either to a project or a group.") % { timebox_name: timebox_name })
  end

  def issues_finder_params
    { project_id: project_id, group_id: group_id, include_subgroups: group_id.present? }.compact
  end

  # milestone titles must be unique across project and group milestones
  def uniqueness_of_title
    if project
      relation = self.class.for_projects_and_groups([project_id], [project.group&.self_and_ancestors_ids])
    elsif group
      relation = self.class.for_projects_and_groups(group.all_project_ids, [group.self_and_hierarchy])
    end

    title_exists = relation.find_by_title(title)
    errors.add(:title, _("already being used for another group or project %{timebox_name}.") % { timebox_name: timebox_name }) if title_exists
  end
end
