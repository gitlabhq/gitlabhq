class Todo < ActiveRecord::Base
  include Sortable

  ASSIGNED           = 1
  MENTIONED          = 2
  BUILD_FAILED       = 3
  MARKED             = 4
  APPROVAL_REQUIRED  = 5 # This is an EE-only feature
  UNMERGEABLE        = 6
  DIRECTLY_ADDRESSED = 7

  ACTION_NAMES = {
    ASSIGNED => :assigned,
    MENTIONED => :mentioned,
    BUILD_FAILED => :build_failed,
    MARKED => :marked,
    APPROVAL_REQUIRED => :approval_required,
    UNMERGEABLE => :unmergeable,
    DIRECTLY_ADDRESSED => :directly_addressed
  }.freeze

  belongs_to :author, class_name: "User"
  belongs_to :note
  belongs_to :project
  belongs_to :target, -> { auto_include(false) }, polymorphic: true, touch: true # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :user

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :action, :project, :target_type, :user, presence: true
  validates :author, presence: true
  validates :target_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?

  scope :pending, -> { with_state(:pending) }
  scope :done, -> { with_state(:done) }

  state_machine :state, initial: :pending do
    event :done do
      transition [:pending] => :done
    end

    state :pending
    state :done
  end

  after_save :keep_around_commit

  class << self
    # Priority sorting isn't displayed in the dropdown, because we don't show
    # milestones, but still show something if the user has a URL with that
    # selected.
    def sort_by_attribute(method)
      sorted =
        case method.to_s
        when 'priority', 'label_priority' then order_by_labels_priority
        else order_by(method)
        end

      # Break ties with the ID column for pagination
      sorted.order(id: :desc)
    end

    # Order by priority depending on which issue/merge request the Todo belongs to
    # Todos with highest priority first then oldest todos
    # Need to order by created_at last because of differences on Mysql and Postgres when joining by type "Merge_request/Issue"
    def order_by_labels_priority
      params = {
        target_type_column: "todos.target_type",
        target_column: "todos.target_id",
        project_column: "todos.project_id"
      }

      highest_priority = highest_label_priority(params).to_sql

      select("#{table_name}.*, (#{highest_priority}) AS highest_priority")
        .order(Gitlab::Database.nulls_last_order('highest_priority', 'ASC'))
        .order('todos.created_at')
    end
  end

  def unmergeable?
    action == UNMERGEABLE
  end

  def build_failed?
    action == BUILD_FAILED
  end

  def assigned?
    action == ASSIGNED
  end

  def action_name
    ACTION_NAMES[action]
  end

  def body
    if note.present?
      note.note
    else
      target.title
    end
  end

  def for_commit?
    target_type == "Commit"
  end

  # override to return commits, which are not active record
  def target
    if for_commit?
      project.commit(commit_id) rescue nil
    else
      super
    end
  end

  def target_reference
    if for_commit?
      target.reference_link_text(full: true)
    else
      target.to_reference(full: true)
    end
  end

  def self_added?
    author == user
  end

  def self_assigned?
    assigned? && self_added?
  end

  private

  def keep_around_commit
    project.repository.keep_around(self.commit_id)
  end
end
