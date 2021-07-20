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
  include Milestoneable
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
  SEARCHABLE_FIELDS = %w(title description).freeze

  STATE_ID_MAP = {
    opened: 1,
    closed: 2,
    merged: 3,
    locked: 4
  }.with_indifferent_access.freeze

  included do
    cache_markdown_field :title, pipeline: :single_line
    cache_markdown_field :description, issuable_state_filter_enabled: true

    redact_field :description

    belongs_to :author, class_name: 'User'
    belongs_to :updated_by, class_name: 'User'
    belongs_to :last_edited_by, class_name: 'User'

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

    has_many :note_authors, -> { distinct }, through: :notes, source: :author

    has_many :label_links, as: :target, inverse_of: :target
    has_many :labels, through: :label_links
    has_many :todos, as: :target

    has_one :metrics, inverse_of: model_name.singular.to_sym, autosave: true

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

    before_validation :truncate_description_on_import!

    scope :authored, ->(user) { where(author_id: user) }
    scope :not_authored, ->(user) { where.not(author_id: user) }
    scope :recent, -> { reorder(id: :desc) }
    scope :of_projects, ->(ids) { where(project_id: ids) }
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
    scope :assigned_to, ->(users) do
      assignees_class = self.reflect_on_association("#{to_ability_name}_assignees").klass

      condition = assignees_class.where(user_id: users).where(Arel.sql("#{to_ability_name}_id = #{to_ability_name}s.id"))
      where(condition.arel.exists)
    end
    scope :not_assigned_to, ->(users) do
      assignees_class = self.reflect_on_association("#{to_ability_name}_assignees").klass

      condition = assignees_class.where(user_id: users).where(Arel.sql("#{to_ability_name}_id = #{to_ability_name}s.id"))
      where(condition.arel.exists.not)
    end
    # rubocop:enable GitlabSecurity/SqlInjection

    scope :without_particular_labels, ->(label_names) do
      labels_table = Label.arel_table
      label_links_table = LabelLink.arel_table
      issuables_table = klass.arel_table
      inner_query = label_links_table.project('true')
                        .join(labels_table, Arel::Nodes::InnerJoin).on(labels_table[:id].eq(label_links_table[:label_id]))
                        .where(label_links_table[:target_type].eq(name)
                                   .and(label_links_table[:target_id].eq(issuables_table[:id]))
                                   .and(labels_table[:title].in(label_names)))
                        .exists.not

      where(inner_query)
    end

    scope :without_label, -> { joins("LEFT OUTER JOIN label_links ON label_links.target_type = '#{name}' AND label_links.target_id = #{table_name}.id").where(label_links: { id: nil }) }
    scope :with_label_ids, ->(label_ids) { joins(:label_links).where(label_links: { label_id: label_ids }) }
    scope :join_project, -> { joins(:project) }
    scope :inc_notes_with_associations, -> { includes(notes: [:project, :author, :award_emoji]) }
    scope :references_project, -> { references(:project) }
    scope :non_archived, -> { join_project.where(projects: { archived: false }) }

    scope :includes_for_bulk_update, -> do
      associations = %i[author assignees epic group labels metrics project source_project target_project].select do |association|
        reflect_on_association(association)
      end

      includes(*associations)
    end

    attr_mentionable :title, pipeline: :single_line
    attr_mentionable :description

    participant :author
    participant :notes_with_associations
    participant :assignees

    strip_attributes :title

    class << self
      def labels_hash
        issue_labels = Hash.new { |h, k| h[k] = [] }

        relation = unscoped.where(id: self.select(:id)).eager_load(:labels)
        relation.pluck(:id, 'labels.title').each do |issue_id, label|
          issue_labels[issue_id] << label if label.present?
        end

        issue_labels
      end

      def locking_enabled?
        false
      end
    end

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

    def allows_reviewers?
      false
    end

    def supports_time_tracking?
      is_a?(TimeTrackable)
    end

    def supports_severity?
      incident?
    end

    def incident?
      is_a?(Issue) && super
    end

    def supports_issue_type?
      is_a?(Issue)
    end

    def supports_assignee?
      false
    end

    def severity
      return IssuableSeverity::DEFAULT unless supports_severity?

      issuable_severity&.severity || IssuableSeverity::DEFAULT
    end

    private

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
    def participant_includes
      [:assignees, :author, { notes: [:author, :award_emoji] }]
    end

    # Searches for records with a matching title.
    #
    # This method uses ILIKE on PostgreSQL.
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
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String
    # matched_columns - Modify the scope of the query. 'title', 'description' or joining them with a comma.
    #
    # Returns an ActiveRecord::Relation.
    def full_search(query, matched_columns: nil, use_minimum_char_limit: true)
      if matched_columns
        matched_columns = matched_columns.to_s.split(',')
        matched_columns &= SEARCHABLE_FIELDS
        matched_columns.map!(&:to_sym)
      end

      search_columns = matched_columns.presence || [:title, :description]

      fuzzy_search(query, search_columns, use_minimum_char_limit: use_minimum_char_limit)
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

    def order_labels_priority(direction = 'ASC', excluded_labels: [], extra_select_columns: [], with_cte: false)
      highest_priority = highest_label_priority(
        target_type: name,
        target_column: "#{table_name}.id",
        project_column: "#{table_name}.#{project_foreign_key}",
        excluded_labels: excluded_labels
      ).to_sql

      # When using CTE make sure to select the same columns that are on the group_by clause.
      # This prevents errors when ignored columns are present in the database.
      issuable_columns = with_cte ? issue_grouping_columns(use_cte: with_cte) : "#{table_name}.*"
      group_columns = issue_grouping_columns(use_cte: with_cte) + ["highest_priorities.label_priority"]

      extra_select_columns.unshift("highest_priorities.label_priority as highest_priority")

      select(issuable_columns)
        .select(extra_select_columns)
        .from("#{table_name}")
        .joins("JOIN LATERAL(#{highest_priority}) as highest_priorities ON TRUE")
        .group(group_columns)
        .reorder(Gitlab::Database.nulls_last_order('highest_priority', direction))
    end

    def with_label(title, sort = nil)
      if title.is_a?(Array) && title.size > 1
        joins(:labels).where(labels: { title: title }).group(*grouping_columns(sort)).having("COUNT(DISTINCT labels.title) = #{title.size}")
      else
        joins(:labels).where(labels: { title: title })
      end
    end

    def any_label(sort = nil)
      if sort
        joins(:label_links).group(*grouping_columns(sort))
      else
        joins(:label_links).distinct
      end
    end

    # Includes table keys in group by clause when sorting
    # preventing errors in postgres
    #
    # Returns an array of arel columns
    def grouping_columns(sort)
      sort = sort.to_s
      grouping_columns = [arel_table[:id]]

      if %w(milestone_due_desc milestone_due_asc milestone).include?(sort)
        milestone_table = Milestone.arel_table
        grouping_columns << milestone_table[:id]
        grouping_columns << milestone_table[:due_date]
      elsif %w(merged_at_desc merged_at_asc).include?(sort)
        grouping_columns << MergeRequest::Metrics.arel_table[:merged_at]
      end

      grouping_columns
    end

    # Includes all table keys in group by clause when sorting
    # preventing errors in postgres when using CTE search optimisation
    #
    # Returns an array of arel columns
    def issue_grouping_columns(use_cte: false)
      if use_cte
        attribute_names.map { |attr| arel_table[attr.to_sym] }
      else
        [arel_table[:id]]
      end
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

  def assignee_or_author?(user)
    author_id == user.id || assignees.exists?(user.id)
  end

  def today?
    Date.today == created_at.to_date
  end

  def created_hours_ago
    (Time.now.utc.to_i - created_at.utc.to_i) / 3600
  end

  def new?
    created_hours_ago < 24
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
    participant?(user)
  end

  def can_assign_epic?(user)
    false
  end

  def to_hook_data(user, old_associations: {})
    changes = previous_changes

    if old_associations
      old_labels = old_associations.fetch(:labels, labels)
      old_assignees = old_associations.fetch(:assignees, assignees)
      old_severity = old_associations.fetch(:severity, severity)

      if old_labels != labels
        changes[:labels] = [old_labels.map(&:hook_attrs), labels.map(&:hook_attrs)]
      end

      if old_assignees != assignees
        changes[:assignees] = [old_assignees.map(&:hook_attrs), assignees.map(&:hook_attrs)]
      end

      if supports_severity? && old_severity != severity
        changes[:severity] = [old_severity, severity]
      end

      if self.respond_to?(:total_time_spent)
        old_total_time_spent = old_associations.fetch(:total_time_spent, total_time_spent)
        old_time_change = old_associations.fetch(:time_change, time_change)

        if old_total_time_spent != total_time_spent
          changes[:total_time_spent] = [old_total_time_spent, total_time_spent]
          changes[:time_change] = [old_time_change, time_change]
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
end

Issuable.prepend_mod_with('Issuable')
