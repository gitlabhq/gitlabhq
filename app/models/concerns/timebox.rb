# frozen_string_literal: true

module Timebox
  extend ActiveSupport::Concern

  include AtomicInternalId
  include CacheMarkdownField
  include IidRoutes
  include StripAttribute

  included do
    alias_method :timebox_id, :id

    validates :group, presence: true, unless: :project
    validates :project, presence: true, unless: :group
    validates :title, presence: true

    validate :uniqueness_of_title, if: :title_changed?
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
    scope :active, -> { with_state(:active) }
    scope :closed, -> { with_state(:closed) }
    scope :for_projects, -> { where(group: nil).includes(:project) }

    scope :for_projects_and_groups, -> (projects, groups) do
      projects = projects.compact if projects.is_a? Array
      projects = [] if projects.nil?

      groups = groups.compact if groups.is_a? Array
      groups = [] if groups.nil?

      where(project_id: projects).or(where(group_id: groups))
    end

    scope :within_timeframe, -> (start_date, end_date) do
      where('start_date is not NULL or due_date is not NULL')
          .where('start_date is NULL or start_date <= ?', end_date)
          .where('due_date is NULL or due_date >= ?', start_date)
    end

    strip_attributes :title

    alias_attribute :name, :title
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

  private

  # Timebox titles must be unique across project and group timeboxes
  def uniqueness_of_title
    if project
      relation = self.class.for_projects_and_groups([project_id], [project.group&.id])
    elsif group
      relation = self.class.for_projects_and_groups(group.projects.select(:id), [group.id])
    end

    title_exists = relation.find_by_title(title)
    errors.add(:title, _("already being used for another group or project %{timebox_name}.") % { timebox_name: timebox_name }) if title_exists
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
