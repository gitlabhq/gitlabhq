module SharedMilestoneProperties
  extend ActiveSupport::Concern

  include StripAttribute
  include CacheMarkdownField

  included do
    has_many :issues
    has_many :merge_requests
    has_many :labels, -> { distinct.reorder('labels.title') },  through: :issues

    validate :uniqueness_of_title, if: :title_changed?

    scope :active, -> { with_state(:active) }
    scope :closed, -> { with_state(:closed) }

    validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }
    strip_attributes :title
    alias_attribute :name, :title

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

    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description
  end

  module ClassMethods
    def filter_by_state(milestones, state)
      case state
      when 'closed' then milestones.closed
      when 'all' then milestones
      else milestones.active
      end
    end
  end

  def start_date_should_be_less_than_due_date
    if due_date <= start_date
      errors.add(:start_date, "Can't be greater than due date")
    end
  end

  def safe_title
    title.to_slug.normalize.to_s
  end

  # Milestone title must be unique across project milestones and group milestones
  def uniqueness_of_title
    title_exists = group.milestones.find_by_title(title).present? if is_group_milestone?

    if is_project_milestone?
      title_exists = project.milestones.find_by_title(title)
      title_exists ||= project.group.milestones.find_by_title(title)
    end

    errors.add(:title, "Must be unique across project milestones and group milestones.") if title_exists
  end
end
