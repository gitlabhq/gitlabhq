# frozen_string_literal: true

module Timebox
  extend ActiveSupport::Concern

  include AtomicInternalId
  include CacheMarkdownField
  include Gitlab::SQL::Pattern
  include IidRoutes
  include Referable
  include StripAttribute
  include FromUnion

  TimeboxStruct = Struct.new(:title, :name, :id) do
    include GlobalID::Identification

    # Ensure these models match the interface required for exporting
    def serializable_hash(_opts = {})
      { title: title, name: name, id: id }
    end

    def self.declarative_policy_class
      "TimeboxPolicy"
    end
  end

  # Represents a "No Timebox" state used for filtering Issues and Merge
  # Requests that have no timeboxes assigned.
  None = TimeboxStruct.new('No Timebox', 'No Timebox', 0)
  Any = TimeboxStruct.new('Any Timebox', '', -1)
  Upcoming = TimeboxStruct.new('Upcoming', '#upcoming', -2)
  Started = TimeboxStruct.new('Started', '#started', -3)

  included do
    # Defines the same constants above, but inside the including class.
    const_set :None, TimeboxStruct.new("No #{self.name}", "No #{self.name}", 0)
    const_set :Any, TimeboxStruct.new("Any #{self.name}", '', -1)
    const_set :Upcoming, TimeboxStruct.new('Upcoming', '#upcoming', -2)
    const_set :Started, TimeboxStruct.new('Started', '#started', -3)

    alias_method :timebox_id, :id

    validates :group, presence: true, unless: :project
    validates :project, presence: true, unless: :group
    validates :title, presence: true

    validate :timebox_type_check
    validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }
    validate :dates_within_4_digits

    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description

    belongs_to :project
    belongs_to :group

    has_many :issues
    has_many :labels, -> { distinct.reorder('labels.title') }, through: :issues
    has_many :merge_requests

    scope :of_projects, ->(ids) { where(project_id: ids) }
    scope :of_groups, ->(ids) { where(group_id: ids) }
    scope :closed, -> { with_state(:closed) }
    scope :for_projects, -> { where(group: nil).includes(:project) }
    scope :with_title, -> (title) { where(title: title) }

    scope :for_projects_and_groups, -> (projects, groups) do
      projects = projects.compact if projects.is_a? Array
      projects = [] if projects.nil?

      groups = groups.compact if groups.is_a? Array
      groups = [] if groups.nil?

      from_union([where(project_id: projects), where(group_id: groups)], remove_duplicates: false)
    end

    # A timebox is within the timeframe (start_date, end_date) if it overlaps
    # with that timeframe:
    #
    #        [  timeframe   ]
    #  ----| ................     # Not overlapping
    #   |--| ................     # Not overlapping
    #  ------|...............     # Overlapping
    #  -----------------------|   # Overlapping
    #  ---------|............     # Overlapping
    #     |-----|............     # Overlapping
    #        |--------------|     # Overlapping
    #     |--------------------|  # Overlapping
    #        ...|-----|......     # Overlapping
    #        .........|-----|     # Overlapping
    #        .........|---------  # Overlapping
    #      |--------------------  # Overlapping
    #        .........|--------|  # Overlapping
    #        ...............|--|  # Overlapping
    #        ............... |-|  # Not Overlapping
    #        ............... |--  # Not Overlapping
    #
    # where: . = in timeframe
    #        ---| no start
    #        |--- no end
    #        |--| defined start and end
    #
    scope :within_timeframe, -> (start_date, end_date) do
      where('start_date is not NULL or due_date is not NULL')
        .where('start_date is NULL or start_date <= ?', end_date)
        .where('due_date is NULL or due_date >= ?', start_date)
    end

    strip_attributes :title

    alias_attribute :name, :title
  end

  class_methods do
    # Searches for timeboxes with a matching title or description.
    #
    # This method uses ILIKE on PostgreSQL
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      fuzzy_search(query, [:title, :description])
    end

    # Searches for timeboxes with a matching title.
    #
    # This method uses ILIKE on PostgreSQL
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search_title(query)
      fuzzy_search(query, [:title])
    end

    def filter_by_state(timeboxes, state)
      case state
      when 'closed' then timeboxes.closed
      when 'all' then timeboxes
      else timeboxes.active
      end
    end

    def count_by_state
      reorder(nil).group(:state).count
    end

    def predefined_id?(id)
      [Any.id, None.id, Upcoming.id, Started.id].include?(id)
    end

    def predefined?(timebox)
      predefined_id?(timebox&.id)
    end
  end

  ##
  # Returns the String necessary to reference a Timebox in Markdown. Group
  # timeboxes only support name references, and do not support cross-project
  # references.
  #
  # format - Symbol format to use (default: :iid, optional: :name)
  #
  # Examples:
  #
  #   Milestone.first.to_reference                           # => "%1"
  #   Iteration.first.to_reference(format: :name)            # => "*iteration:\"goal\""
  #   Milestone.first.to_reference(cross_namespace_project)  # => "gitlab-org/gitlab-foss%1"
  #   Iteration.first.to_reference(same_namespace_project)   # => "gitlab-foss*iteration:1"
  #
  def to_reference(from = nil, format: :name, full: false)
    format_reference = timebox_format_reference(format)
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

  def title=(value)
    write_attribute(:title, sanitize_title(value)) if value.present?
  end

  def timebox_name
    model_name.singular
  end

  def group_timebox?
    group_id.present?
  end

  def project_timebox?
    project_id.present?
  end

  def safe_title
    title.to_slug.normalize.to_s
  end

  def resource_parent
    group || project
  end

  def to_ability_name
    model_name.singular
  end

  def merge_requests_enabled?
    if group_timebox?
      # Assume that groups have at least one project with merge requests enabled.
      # Otherwise, we would need to load all of the projects from the database.
      true
    elsif project_timebox?
      project&.merge_requests_enabled?
    end
  end

  def weight_available?
    resource_parent&.feature_available?(:issue_weights)
  end

  private

  def timebox_format_reference(format = :iid)
    raise ArgumentError, _('Unknown format') unless [:iid, :name].include?(format)

    if group_timebox? && format == :iid
      raise ArgumentError, _('Cannot refer to a group %{timebox_type} by an internal id!') % { timebox_type: timebox_name }
    end

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      iid
    end
  end

  # Timebox should be either a project timebox or a group timebox
  def timebox_type_check
    if group_id && project_id
      field = project_id_changed? ? :project_id : :group_id
      errors.add(field, _("%{timebox_name} should belong either to a project or a group.") % { timebox_name: timebox_name })
    end
  end

  def start_date_should_be_less_than_due_date
    if due_date <= start_date
      errors.add(:due_date, _("must be greater than start date"))
    end
  end

  def dates_within_4_digits
    if start_date && start_date > Date.new(9999, 12, 31)
      errors.add(:start_date, _("date must not be after 9999-12-31"))
    end

    if due_date && due_date > Date.new(9999, 12, 31)
      errors.add(:due_date, _("date must not be after 9999-12-31"))
    end
  end

  def sanitize_title(value)
    CGI.unescape_html(Sanitize.clean(value.to_s))
  end
end
