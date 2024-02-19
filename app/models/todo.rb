# frozen_string_literal: true

class Todo < ApplicationRecord
  include Sortable
  include FromUnion
  include EachBatch

  # Time to wait for todos being removed when not visible for user anymore.
  # Prevents TODOs being removed by mistake, for example, removing access from a user
  # and giving it back again.
  WAIT_FOR_DELETE = 1.hour

  # Actions
  ASSIGNED            = 1
  MENTIONED           = 2
  BUILD_FAILED        = 3
  MARKED              = 4
  APPROVAL_REQUIRED   = 5 # This is an EE-only feature
  UNMERGEABLE         = 6
  DIRECTLY_ADDRESSED  = 7
  MERGE_TRAIN_REMOVED = 8 # This is an EE-only feature
  REVIEW_REQUESTED    = 9
  MEMBER_ACCESS_REQUESTED = 10
  REVIEW_SUBMITTED = 11 # This is an EE-only feature
  OKR_CHECKIN_REQUESTED = 12 # This is an EE-only feature
  ADDED_APPROVER = 13 # This is an EE-only feature

  ACTION_NAMES = {
    ASSIGNED => :assigned,
    REVIEW_REQUESTED => :review_requested,
    MENTIONED => :mentioned,
    BUILD_FAILED => :build_failed,
    MARKED => :marked,
    APPROVAL_REQUIRED => :approval_required,
    UNMERGEABLE => :unmergeable,
    DIRECTLY_ADDRESSED => :directly_addressed,
    MERGE_TRAIN_REMOVED => :merge_train_removed,
    MEMBER_ACCESS_REQUESTED => :member_access_requested,
    REVIEW_SUBMITTED => :review_submitted,
    OKR_CHECKIN_REQUESTED => :okr_checkin_requested,
    ADDED_APPROVER => :added_approver
  }.freeze

  ACTIONS_MULTIPLE_ALLOWED = [Todo::MENTIONED, Todo::DIRECTLY_ADDRESSED, Todo::MEMBER_ACCESS_REQUESTED].freeze

  belongs_to :author, class_name: "User"
  belongs_to :note
  belongs_to :project
  belongs_to :group
  belongs_to :target, -> {
    if self.klass.respond_to?(:with_api_entity_associations)
      self.with_api_entity_associations
    else
      self
    end
  }, polymorphic: true, touch: true # rubocop:disable Cop/PolymorphicAssociations

  belongs_to :user
  belongs_to :issue, -> { where("target_type = 'Issue'") }, foreign_key: :target_id

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :action, :target_type, :user, presence: true
  validates :author, presence: true
  validates :target_id, presence: true, unless: :for_commit?
  validates :commit_id, presence: true, if: :for_commit?
  validates :project, presence: true, unless: :group_id
  validates :group, presence: true, unless: :project_id

  scope :pending, -> { with_state(:pending) }
  scope :done, -> { with_state(:done) }
  scope :for_action, -> (action) { where(action: action) }
  scope :for_author, -> (author) { where(author: author) }
  scope :for_user, -> (user) { where(user: user) }
  scope :for_project, -> (projects) { where(project: projects) }
  scope :for_note, -> (notes) { where(note: notes) }
  scope :for_undeleted_projects, -> { joins(:project).merge(Project.without_deleted) }
  scope :for_group, -> (group) { where(group: group) }
  scope :for_type, -> (type) { where(target_type: type) }
  scope :for_target, -> (id) { where(target_id: id) }
  scope :for_commit, -> (id) { where(commit_id: id) }
  scope :not_in_users, -> (user_ids) { where.not('todos.user_id' => user_ids) }
  scope :with_entity_associations, -> do
    preload(:target, :author, :note, group: :route, project: [:route, :group, { namespace: [:route, :owner] }, :project_setting])
  end
  scope :joins_issue_and_assignees, -> { left_joins(issue: :assignees) }
  scope :for_internal_notes, -> { joins(:note).where(note: { confidential: true }) }
  scope :with_preloaded_user, -> { preload(:user) }

  enum resolved_by_action: { system_done: 0, api_all_done: 1, api_done: 2, mark_all_done: 3, mark_done: 4 }, _prefix: :resolved_by

  state_machine :state, initial: :pending do
    event :done do
      transition [:pending] => :done
    end

    state :pending
    state :done
  end

  after_save :keep_around_commit, if: :commit_id

  class << self
    # Returns all todos for the given group ids and their descendants.
    #
    # group_ids - Group Ids to retrieve todos for.
    #
    # Returns an `ActiveRecord::Relation`.
    def for_group_ids_and_descendants(group_ids)
      groups = Group.where(id: group_ids).self_and_descendants

      from_union(
        [
          for_project(Project.for_group(groups)),
          for_group(groups)
        ])
    end

    # Returns `true` if the current user has any todos for the given target with the optional given state.
    #
    # target - The value of the `target_type` column, such as `Issue`.
    # state - The value of the `state` column, such as `pending` or `done`.
    def any_for_target?(target, state = nil)
      conditions = {}

      if target.respond_to?(:todoable_target_type_name)
        conditions[:target_type] = target.todoable_target_type_name
        conditions[:target_id] = target.id
      else
        conditions[:target] = target
      end

      conditions[:state] = state unless state.nil?

      exists?(conditions)
    end

    # Updates attributes of a relation of todos to the new state.
    #
    # new_attributes - The new attributes of the todos.
    #
    # Returns an `Array` containing the IDs of the updated todos.
    def batch_update(**new_attributes)
      # Only update those that have different state
      base = where.not(state: new_attributes[:state]).except(:order)
      ids = base.pluck(:id)

      base.update_all(new_attributes.merge(updated_at: Time.current))

      ids
    end

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
      highest_priority = highest_label_priority(
        target_type_column: "todos.target_type",
        target_column: "todos.target_id",
        project_column: "todos.project_id"
      ).arel.as('highest_priority')

      select(arel_table[Arel.star], highest_priority)
        .order(Arel.sql('highest_priority').asc.nulls_last)
        .order('todos.created_at')
    end

    def distinct_user_ids
      distinct.pluck(:user_id)
    end

    # Count todos grouped by user_id and state, using an UNION query
    # so we can utilize the partial indexes for each state.
    def count_grouped_by_user_id_and_state
      grouped_count = select(:user_id, 'count(id) AS count').group(:user_id)

      done = grouped_count.where(state: :done).select("'done' AS state")
      pending = grouped_count.where(state: :pending).select("'pending' AS state")
      union = unscoped.from_union([done, pending], remove_duplicates: false)
        .select(:user_id, :count, :state)

      connection.select_all(union).each_with_object({}) do |row, counts|
        counts[[row['user_id'], row['state']]] = row['count']
      end
    end
  end

  def resource_parent
    project || group
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

  def review_requested?
    action == REVIEW_REQUESTED
  end

  def merge_train_removed?
    action == MERGE_TRAIN_REMOVED
  end

  def member_access_requested?
    action == MEMBER_ACCESS_REQUESTED
  end

  def review_submitted?
    action == REVIEW_SUBMITTED
  end

  def member_access_type
    target.class.name.downcase
  end

  def access_request_url(only_path: false)
    if target.instance_of? Group
      Gitlab::Routing.url_helpers.group_group_members_url(self.target, tab: 'access_requests', only_path: only_path)
    elsif target.instance_of? Project
      Gitlab::Routing.url_helpers.project_project_members_url(self.target, tab: 'access_requests', only_path: only_path)
    else
      ""
    end
  end

  def done?
    state == 'done'
  end

  def action_name
    ACTION_NAMES[action]
  end

  def body
    if note.present?
      note.note
    elsif member_access_requested?
      target.full_path
    else
      target.title
    end
  end

  def for_commit?
    target_type == "Commit"
  end

  def for_design?
    target_type == DesignManagement::Design.name
  end

  def for_alert?
    target_type == AlertManagement::Alert.name
  end

  def for_issue_or_work_item?
    [Issue.name, WorkItem.name].any?(target_type)
  end

  # override to return commits, which are not active record
  def target
    if for_commit?
      begin
        project.commit(commit_id)
      rescue StandardError
        nil
      end
    else
      super
    end
  end

  def target_reference
    if for_commit?
      target.reference_link_text
    elsif member_access_requested?
      target.full_path
    else
      target.to_reference
    end
  end

  def self_added?
    author == user
  end

  def self_assigned?
    self_added? && (assigned? || review_requested?)
  end

  private

  def keep_around_commit
    project.repository.keep_around(self.commit_id, source: self.class.name)
  end
end

Todo.prepend_mod_with('Todo')
