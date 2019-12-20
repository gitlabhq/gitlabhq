# frozen_string_literal: true

# == Issuable concern
#
# Contains common functionality shared between Issues and MergeRequests
#
# Used by Issue, MergeRequest, Epic
#
module Issuable
  extend ActiveSupport::Concern
  include Gitlab::SQL::Pattern
  include Redactable
  include CacheMarkdownField
  include Participable
  include Mentionable
  include Subscribable
  include StripAttribute
  include Awardable
  include Taskable
  include Importable
  include Editable
  include AfterCommitQueue
  include Sortable
  include CreatedAtFilterable
  include UpdatedAtFilterable
  include ClosedAtFilterable
  include VersionedDescription

  TITLE_LENGTH_MAX = 255
  TITLE_HTML_LENGTH_MAX = 800
  DESCRIPTION_LENGTH_MAX = 1.megabyte
  DESCRIPTION_HTML_LENGTH_MAX = 5.megabytes

  STATE_ID_MAP = {
    opened: 1,
    closed: 2,
    merged: 3,
    locked: 4
  }.with_indifferent_access.freeze

  # This object is used to gather issuable meta data for displaying
  # upvotes, downvotes, notes and closing merge requests count for issues and merge requests
  # lists avoiding n+1 queries and improving performance.
  IssuableMeta = Struct.new(:upvotes, :downvotes, :user_notes_count, :mrs_count) do
    def merge_requests_count(user = nil)
      mrs_count
    end
  end

  included do
    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description, issuable_state_filter_enabled: true

    redact_field :description

    belongs_to :author, class_name: 'User'
    belongs_to :updated_by, class_name: 'User'
    belongs_to :last_edited_by, class_name: 'User'
    belongs_to :milestone

    has_many :notes, as: :noteable, inverse_of: :noteable, dependent: :destroy do # rubocop:disable Cop/ActiveRecordDependent
      def authors_loaded?
        # We check first if we're loaded to not load unnecessarily.
        loaded? && to_a.all? { |note| note.association(:author).loaded? }
      end

      def award_emojis_loaded?
        # We check first if we're loaded to not load unnecessarily.
        loaded? && to_a.all? { |note| note.association(:award_emoji).loaded? }
      end
    end

    has_many :label_links, as: :target, dependent: :destroy, inverse_of: :target # rubocop:disable Cop/ActiveRecordDependent
    has_many :labels, through: :label_links
    has_many :todos, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

    has_one :metrics

    delegate :name,
             :email,
             :public_email,
             to: :author,
             allow_nil: true,
             prefix: true

    validates :author, presence: true
    validates :title, presence: true, length: { maximum: TITLE_LENGTH_MAX }
    # we validate the description against DESCRIPTION_LENGTH_MAX only for Issuables being created
    # to avoid breaking the existing Issuables which may have their descriptions longer
    validates :description, length: { maximum: DESCRIPTION_LENGTH_MAX }, allow_blank: true, on: :create
    validate :description_max_length_for_new_records_is_valid, on: :update
    validate :milestone_is_valid

    before_validation :truncate_description_on_import!

    scope :authored, ->(user) { where(author_id: user) }
    scope :recent, -> { reorder(id: :desc) }
    scope :of_projects, ->(ids) { where(project_id: ids) }
    scope :of_milestones, ->(ids) { where(milestone_id: ids) }
    scope :any_milestone, -> { where('milestone_id IS NOT NULL') }
    scope :with_milestone, ->(title) { left_joins_milestones.where(milestones: { title: title }) }
    scope :any_release, -> { joins_milestone_releases }
    scope :with_release, -> (tag, project_id) { joins_milestone_releases.where( milestones: { releases: { tag: tag, project_id: project_id } } ) }
    scope :opened, -> { with_state(:opened) }
    scope :only_opened, -> { with_state(:opened) }
    scope :closed, -> { with_state(:closed) }

    # rubocop:disable GitlabSecurity/SqlInjection
    # The `to_ability_name` method is not an user input.
    scope :assigned, -> do
      where("EXISTS (SELECT TRUE FROM #{to_ability_name}_assignees WHERE #{to_ability_name}_id = #{to_ability_name}s.id)")
    end
    scope :unassigned, -> do
      where("NOT EXISTS (SELECT TRUE FROM #{to_ability_name}_assignees WHERE #{to_ability_name}_id = #{to_ability_name}s.id)")
    end
    scope :assigned_to, ->(u) do
      where("EXISTS (SELECT TRUE FROM #{to_ability_name}_assignees WHERE user_id = ? AND #{to_ability_name}_id = #{to_ability_name}s.id)", u.id)
    end
    # rubocop:enable GitlabSecurity/SqlInjection

    scope :left_joins_milestones,    -> { joins("LEFT OUTER JOIN milestones ON #{table_name}.milestone_id = milestones.id") }
    scope :order_milestone_due_desc, -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date DESC')) }
    scope :order_milestone_due_asc,  -> { left_joins_milestones.reorder(Arel.sql('milestones.due_date IS NULL, milestones.id IS NULL, milestones.due_date ASC')) }

    scope :without_release, -> do
      joins("LEFT OUTER JOIN milestone_releases ON #{table_name}.milestone_id = milestone_releases.milestone_id")
        .where('milestone_releases.release_id IS NULL')
    end

    scope :joins_milestone_releases, -> do
      joins("JOIN milestone_releases ON #{table_name}.milestone_id = milestone_releases.milestone_id
             JOIN releases ON milestone_releases.release_id = releases.id").distinct
    end

    scope :without_label, -> { joins("LEFT OUTER JOIN label_links ON label_links.target_type = '#{name}' AND label_links.target_id = #{table_name}.id").where(label_links: { id: nil }) }
    scope :any_label, -> { joins(:label_links).group(:id) }
    scope :join_project, -> { joins(:project) }
    scope :inc_notes_with_associations, -> { includes(notes: [:project, :author, :award_emoji]) }
    scope :references_project, -> { references(:project) }
    scope :non_archived, -> { join_project.where(projects: { archived: false }) }

    attr_mentionable :title, pipeline: :single_line
    attr_mentionable :description

    participant :author
    participant :notes_with_associations
    participant :assignees

    strip_attributes :title

    # We want to use optimistic lock for cases when only title or description are involved
    # http://api.rubyonrails.org/classes/ActiveRecord/Locking/Optimistic.html
    def locking_enabled?
      will_save_change_to_title? || will_save_change_to_description?
    end

    def allows_multiple_assignees?
      false
    end

    def has_multiple_assignees?
      assignees.count > 1
    end

    private

    def milestone_is_valid
      errors.add(:milestone_id, message: "is invalid") if respond_to?(:milestone_id) && milestone_id.present? && !milestone_available?
    end

    def description_max_length_for_new_records_is_valid
      if new_record? && description.length > Issuable::DESCRIPTION_LENGTH_MAX
        errors.add(:description, :too_long, count: Issuable::DESCRIPTION_LENGTH_MAX)
      end
    end

    def truncate_description_on_import!
      self.description = description&.slice(0, Issuable::DESCRIPTION_LENGTH_MAX) if importing?
    end
  end

  class_methods do
    # Searches for records with a matching title.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    #
    # Returns an ActiveRecord::Relation.
    def search(query)
      fuzzy_search(query, [:title])
    end

    def available_states
      @available_states ||= STATE_ID_MAP.slice(*available_state_names)
    end

    # Available state names used to persist state_id column using state machine
    #
    # Override this on subclasses if different states are needed
    #
    # Check MergeRequest.available_states_names for example
    def available_state_names
      [:opened, :closed]
    end

    # Searches for records with a matching title or description.
    #
    # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
    #
    # query - The search query as a String
    # matched_columns - Modify the scope of the query. 'title', 'description' or joining them with a comma.
    #
    # Returns an ActiveRecord::Relation.
    def full_search(query, matched_columns: 'title,description', use_minimum_char_limit: true)
      allowed_columns = [:title, :description]
      matched_columns = matched_columns.to_s.split(',').map(&:to_sym)
      matched_columns &= allowed_columns

      # Matching title or description if the matched_columns did not contain any allowed columns.
      matched_columns = [:title, :description] if matched_columns.empty?

      fuzzy_search(query, matched_columns, use_minimum_char_limit: use_minimum_char_limit)
    end

    def simple_sorts
      super.except('name_asc', 'name_desc')
    end

    def sort_by_attribute(method, excluded_labels: [])
      sorted =
        case method.to_s
        when 'downvotes_desc'                                 then order_downvotes_desc
        when 'label_priority', 'label_priority_asc'           then order_labels_priority(excluded_labels: excluded_labels)
        when 'label_priority_desc'                            then order_labels_priority('DESC', excluded_labels: excluded_labels)
        when 'milestone', 'milestone_due_asc'                 then order_milestone_due_asc
        when 'milestone_due_desc'                             then order_milestone_due_desc
        when 'popularity_asc'                                 then order_upvotes_asc
        when 'popularity', 'popularity_desc', 'upvotes_desc'  then order_upvotes_desc
        when 'priority', 'priority_asc'                       then order_due_date_and_labels_priority(excluded_labels: excluded_labels)
        when 'priority_desc'                                  then order_due_date_and_labels_priority('DESC', excluded_labels: excluded_labels)
        else order_by(method)
        end

      # Break ties with the ID column for pagination
      sorted.with_order_id_desc
    end

    def order_due_date_and_labels_priority(direction = 'ASC', excluded_labels: [])
      # The order_ methods also modify the query in other ways:
      #
      # - For milestones, we add a JOIN.
      # - For label priority, we change the SELECT, and add a GROUP BY.#
      #
      # After doing those, we need to reorder to the order we want. The existing
      # ORDER BYs won't work because:
      #
      # 1. We need milestone due date first.
      # 2. We can't ORDER BY a column that isn't in the GROUP BY and doesn't
      #    have an aggregate function applied, so we do a useless MIN() instead.
      #
      milestones_due_date = 'MIN(milestones.due_date)'

      order_milestone_due_asc
        .order_labels_priority(excluded_labels: excluded_labels, extra_select_columns: [milestones_due_date])
        .reorder(Gitlab::Database.nulls_last_order(milestones_due_date, direction),
                Gitlab::Database.nulls_last_order('highest_priority', direction))
    end

    def order_labels_priority(direction = 'ASC', excluded_labels: [], extra_select_columns: [])
      params = {
        target_type: name,
        target_column: "#{table_name}.id",
        project_column: "#{table_name}.#{project_foreign_key}",
        excluded_labels: excluded_labels
      }

      highest_priority = highest_label_priority(params).to_sql

      select_columns = [
        "#{table_name}.*",
        "(#{highest_priority}) AS highest_priority"
      ] + extra_select_columns

      select(select_columns.join(', '))
        .group(arel_table[:id])
        .reorder(Gitlab::Database.nulls_last_order('highest_priority', direction))
    end

    def with_label(title, sort = nil)
      if title.is_a?(Array) && title.size > 1
        joins(:labels).where(labels: { title: title }).group(*grouping_columns(sort)).having("COUNT(DISTINCT labels.title) = #{title.size}")
      else
        joins(:labels).where(labels: { title: title })
      end
    end

    # Includes table keys in group by clause when sorting
    # preventing errors in postgres
    #
    # Returns an array of arel columns
    def grouping_columns(sort)
      grouping_columns = [arel_table[:id]]

      if %w(milestone_due_desc milestone_due_asc milestone).include?(sort)
        milestone_table = Milestone.arel_table
        grouping_columns << milestone_table[:id]
        grouping_columns << milestone_table[:due_date]
      end

      grouping_columns
    end

    def to_ability_name
      model_name.singular
    end

    def parent_class
      ::Project
    end
  end

  def state
    self.class.available_states.key(state_id)
  end

  def state=(value)
    self.state_id = self.class.available_states[value]
  end

  def resource_parent
    project
  end

  def milestone_available?
    project_id == milestone&.project_id || project.ancestors_upto.compact.include?(milestone&.group)
  end

  def assignee_or_author?(user)
    author_id == user.id || assignees.exists?(user.id)
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end

  def open?
    opened?
  end

  def overdue?
    return false unless respond_to?(:due_date)

    due_date.try(:past?) || false
  end

  def user_notes_count
    if notes.loaded?
      # Use the in-memory association to select and count to avoid hitting the db
      notes.to_a.count { |note| !note.system? }
    else
      # do the count query
      notes.user.count
    end
  end

  def subscribed_without_subscriptions?(user, project)
    participants(user).include?(user)
  end

  def to_hook_data(user, old_associations: {})
    changes = previous_changes

    if old_associations
      old_labels = old_associations.fetch(:labels, [])
      old_assignees = old_associations.fetch(:assignees, [])

      if old_labels != labels
        changes[:labels] = [old_labels.map(&:hook_attrs), labels.map(&:hook_attrs)]
      end

      if old_assignees != assignees
        changes[:assignees] = [old_assignees.map(&:hook_attrs), assignees.map(&:hook_attrs)]
      end

      if self.respond_to?(:total_time_spent)
        old_total_time_spent = old_associations.fetch(:total_time_spent, nil)

        if old_total_time_spent != total_time_spent
          changes[:total_time_spent] = [old_total_time_spent, total_time_spent]
        end
      end
    end

    Gitlab::HookData::IssuableBuilder.new(self).build(user: user, changes: changes)
  end

  def labels_array
    labels.to_a
  end

  def label_names
    labels.order('title ASC').pluck(:title)
  end

  # Convert this Issuable class name to a format usable by Ability definitions
  #
  # Examples:
  #
  #   issuable.class           # => MergeRequest
  #   issuable.to_ability_name # => "merge_request"
  def to_ability_name
    self.class.to_ability_name
  end

  # Returns a Hash of attributes to be used for Twitter card metadata
  def card_attributes
    {
      'Author'   => author.try(:name),
      'Assignee' => assignee_list
    }
  end

  def assignee_list
    assignees.map(&:name).to_sentence
  end

  def assignee_username_list
    assignees.map(&:username).to_sentence
  end

  def notes_with_associations
    # If A has_many Bs, and B has_many Cs, and you do
    # `A.includes(b: :c).each { |a| a.b.includes(:c) }`, sadly ActiveRecord
    # will do the inclusion again. So, we check if all notes in the relation
    # already have their authors loaded (possibly because the scope
    # `inc_notes_with_associations` was used) and skip the inclusion if that's
    # the case.
    includes = []
    includes << :author unless notes.authors_loaded?
    includes << :award_emoji unless notes.award_emojis_loaded?

    if includes.any?
      notes.includes(includes)
    else
      notes
    end
  end

  def updated_tasks
    Taskable.get_updated_tasks(old_content: previous_changes['description'].first,
                               new_content: description)
  end

  ##
  # Method that checks if issuable can be moved to another project.
  #
  # Should be overridden if issuable can be moved.
  #
  def can_move?(*)
    false
  end

  ##
  # Override in issuable specialization
  #
  def first_contribution?
    false
  end

  def ensure_metrics
    self.metrics || create_metrics
  end

  ##
  # Overridden in MergeRequest
  #
  def wipless_title_changed(old_title)
    old_title != title
  end

  ##
  # Overridden on EE module
  #
  def supports_milestone?
    respond_to?(:milestone_id)
  end
end

Issuable.prepend_if_ee('EE::Issuable') # rubocop: disable Cop/InjectEnterpriseEditionModule
Issuable::ClassMethods.prepend_if_ee('EE::Issuable::ClassMethods')
