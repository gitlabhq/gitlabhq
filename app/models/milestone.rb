class Milestone < ActiveRecord::Base
  # Represents a "No Milestone" state used for filtering Issues and Merge
  # Requests that have no milestone assigned.
  MilestoneStruct = Struct.new(:title, :name, :id)
  None = MilestoneStruct.new('No Milestone', 'No Milestone', 0)
  Any = MilestoneStruct.new('Any Milestone', '', -1)
  Upcoming = MilestoneStruct.new('Upcoming', '#upcoming', -2)
  Started = MilestoneStruct.new('Started', '#started', -3)

  include SharedMilestoneProperties
  include InternalId
  include Sortable
  include Referable
  include Milestoneish

  belongs_to :project

  has_many :events, as: :target, dependent: :destroy

  scope :of_projects, ->(ids) { where(project_id: ids) }

  class << self
    # Searches for milestones matching the given query.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      t = arel_table
      pattern = "%#{query}%"

      where(t[:title].matches(pattern).or(t[:description].matches(pattern)))
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

  def self.sort(method)
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
  # Returns the String necessary to reference this Milestone in Markdown
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
  def to_reference(from_project = nil, format: :iid, full: false)
    format_reference = milestone_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    "#{project.to_reference(from_project, full: full)}#{reference}"
  end

  def reference_link_text(from_project = nil)
    self.title
  end

  def milestoneish_ids
    id
  end

  def can_be_closed?
    active? && issues.opened.count.zero?
  end

  def author_id
    nil
  end

  private

  def uniqueness_of_title
    super(project.group, project)
  end

  def milestone_format_reference(format = :iid)
    raise ArgumentError, 'Unknown format' unless [:iid, :name].include?(format)

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      iid
    end
  end

  def issues_finder_params
    { project_id: project_id }
  end
end
