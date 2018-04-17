class Milestone < ActiveRecord::Base
  # Represents a "No Milestone" state used for filtering Issues and Merge
  # Requests that have no milestone assigned.
  MilestoneStruct = Struct.new(:title, :name, :id)
  None = MilestoneStruct.new('No Milestone', 'No Milestone', 0)
  Any = MilestoneStruct.new('Any Milestone', '', -1)
  Upcoming = MilestoneStruct.new('Upcoming', '#upcoming', -2)
  Started = MilestoneStruct.new('Started', '#started', -3)

  include CacheMarkdownField
  include NonatomicInternalId
  include Sortable
  include Referable
  include StripAttribute
  include Milestoneish
  include Gitlab::SQL::Pattern

  cache_markdown_field :title, pipeline: :single_line
  cache_markdown_field :description

  belongs_to :project
  belongs_to :group

  has_many :issues
  has_many :labels, -> { distinct.reorder('labels.title').auto_include(false) }, through: :issues
  has_many :merge_requests
  has_many :events, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  scope :of_projects, ->(ids) { where(project_id: ids) }
  scope :of_groups, ->(ids) { where(group_id: ids) }
  scope :active, -> { with_state(:active) }
  scope :closed, -> { with_state(:closed) }
  scope :for_projects, -> { where(group: nil).includes(:project) }

  scope :for_projects_and_groups, -> (project_ids, group_ids) do
    conditions = []
    conditions << arel_table[:project_id].in(project_ids) if project_ids&.compact&.any?
    conditions << arel_table[:group_id].in(group_ids) if group_ids&.compact&.any?

    where(conditions.reduce(:or))
  end

  validates :group, presence: true, unless: :project
  validates :project, presence: true, unless: :group

  validate :uniqueness_of_title, if: :title_changed?
  validate :milestone_type_check
  validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }

  strip_attributes :title

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

  alias_attribute :name, :title

  class << self
    # Searches for milestones matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      fuzzy_search(query, [:title, :description])
    end

    def filter_by_state(milestones, state)
      case state
      when 'closed' then milestones.closed
      when 'all' then milestones
      else milestones.active
      end
    end

    def predefined?(milestone)
      milestone == Any ||
        milestone == None ||
        milestone == Upcoming ||
        milestone == Started
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

  def self.upcoming_ids_by_projects(projects)
    rel = unscoped.of_projects(projects).active.where('due_date > ?', Time.now)

    if Gitlab::Database.postgresql?
      rel.order(:project_id, :due_date).select('DISTINCT ON (project_id) id')
    else
      rel
        .group(:project_id)
        .having('due_date = MIN(due_date)')
        .pluck(:id, :project_id, :due_date)
        .map(&:first)
    end
  end

  def participants
    User.joins(assigned_issues: :milestone).where("milestones.id = ?", id).uniq
  end

  def self.sort_by_attribute(method)
    case method.to_s
    when 'due_date_asc'
      reorder(Gitlab::Database.nulls_last_order('due_date', 'ASC'))
    when 'due_date_desc'
      reorder(Gitlab::Database.nulls_last_order('due_date', 'DESC'))
    when 'start_date_asc'
      reorder(Gitlab::Database.nulls_last_order('start_date', 'ASC'))
    when 'start_date_desc'
      reorder(Gitlab::Database.nulls_last_order('start_date', 'DESC'))
    else
      order_by(method)
    end
  end

  ##
  # Returns the String necessary to reference this Milestone in Markdown. Group
  # milestones only support name references, and do not support cross-project
  # references.
  #
  # format - Symbol format to use (default: :iid, optional: :name)
  #
  # Examples:
  #
  #   Milestone.first.to_reference                           # => "%1"
  #   Milestone.first.to_reference(format: :name)            # => "%\"goal\""
  #   Milestone.first.to_reference(cross_namespace_project)  # => "gitlab-org/gitlab-ce%1"
  #   Milestone.first.to_reference(same_namespace_project)   # => "gitlab-ce%1"
  #
  def to_reference(from = nil, format: :name, full: false)
    format_reference = milestone_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if project
      "#{project.to_reference(from, full: full)}#{reference}"
    else
      reference
    end
  end

  def reference_link_text(from = nil)
    self.title
  end

  def milestoneish_ids
    id
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

  def title=(value)
    write_attribute(:title, sanitize_title(value)) if value.present?
  end

  def safe_title
    title.to_slug.normalize.to_s
  end

  def parent
    group || project
  end

  def group_milestone?
    group_id.present?
  end

  def project_milestone?
    project_id.present?
  end

  private

  # Milestone titles must be unique across project milestones and group milestones
  def uniqueness_of_title
    if project
      relation = Milestone.for_projects_and_groups([project_id], [project.group&.id])
    elsif group
      project_ids = group.projects.map(&:id)
      relation = Milestone.for_projects_and_groups(project_ids, [group.id])
    end

    title_exists = relation.find_by_title(title)
    errors.add(:title, "already being used for another group or project milestone.") if title_exists
  end

  # Milestone should be either a project milestone or a group milestone
  def milestone_type_check
    if group_id && project_id
      field = project_id_changed? ? :project_id : :group_id
      errors.add(field, "milestone should belong either to a project or a group.")
    end
  end

  def milestone_format_reference(format = :iid)
    raise ArgumentError, 'Unknown format' unless [:iid, :name].include?(format)

    if group_milestone? && format == :iid
      raise ArgumentError, 'Cannot refer to a group milestone by an internal id!'
    end

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      iid
    end
  end

  def sanitize_title(value)
    CGI.unescape_html(Sanitize.clean(value.to_s))
  end

  def start_date_should_be_less_than_due_date
    if due_date <= start_date
      errors.add(:due_date, "must be greater than start date")
    end
  end

  def issues_finder_params
    { project_id: project_id }
  end
end
