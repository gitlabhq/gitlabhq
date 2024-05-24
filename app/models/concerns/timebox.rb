# frozen_string_literal: true

module Timebox
  extend ActiveSupport::Concern

  include CacheMarkdownField
  include Gitlab::SQL::Pattern
  include Referable
  include StripAttribute

  TimeboxStruct = Struct.new(:title, :name, :id, :class_name) do
    # Ensure these models match the interface required for exporting
    def serializable_hash(_opts = {})
      { title: title, name: name, id: id }
    end

    def self.declarative_policy_class
      "TimeboxPolicy"
    end

    def to_global_id
      ::Gitlab::GlobalId.build(self, model_name: class_name, id: id)
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
    const_set :None, TimeboxStruct.new("No #{self.name}", "No #{self.name}", 0, self.name)
    const_set :Any, TimeboxStruct.new("Any #{self.name}", '', -1, self.name)
    const_set :Upcoming, TimeboxStruct.new('Upcoming', '#upcoming', -2, self.name)
    const_set :Started, TimeboxStruct.new('Started', '#started', -3, self.name)

    alias_method :timebox_id, :id

    validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }
    validate :dates_within_4_digits

    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description, issuable_reference_expansion_enabled: true

    has_many :issues
    has_many :labels, -> { distinct.reorder('labels.title') }, through: :issues
    has_many :merge_requests

    scope :closed, -> { with_state(:closed) }
    scope :with_title, ->(title) { where(title: title) }

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
    scope :within_timeframe, ->(start_date, end_date) do
      where('start_date is not NULL or due_date is not NULL')
        .where('start_date is NULL or start_date <= ?', end_date)
        .where('due_date is NULL or due_date >= ?', start_date)
    end

    strip_attributes! :title

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

    def filter_by_state(timeboxes, state)
      case state
      when 'closed' then timeboxes.closed
      when 'all' then timeboxes
      else timeboxes.active
      end
    end

    def predefined_id?(id)
      [Any.id, None.id, Upcoming.id, Started.id].include?(id)
    end

    def predefined?(timebox)
      predefined_id?(timebox&.id)
    end
  end

  def to_reference
    raise NotImplementedError
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

  def safe_title
    title.to_slug.normalize.to_s
  end

  def resource_parent
    raise NotImplementedError
  end

  def to_ability_name
    model_name.singular
  end

  def merge_requests_enabled?
    raise NotImplementedError
  end

  def weight_available?
    resource_parent&.feature_available?(:issue_weights)
  end

  private

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
