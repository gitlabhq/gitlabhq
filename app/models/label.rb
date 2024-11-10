# frozen_string_literal: true

class Label < ApplicationRecord
  include BaseLabel
  include Referable
  include Subscribable
  include OptionallySearch
  include Sortable
  include FromUnion
  include Presentable
  include EachBatch

  DESCRIPTION_LENGTH_MAX = 512.kilobytes

  has_many :lists, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :priorities, class_name: 'LabelPriority'
  has_many :label_links, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'
  has_many :merge_requests, through: :label_links, source: :target, source_type: 'MergeRequest'

  before_destroy :prevent_locked_label_destroy, prepend: true

  validate :ensure_lock_on_merge_allowed
  validates :title, uniqueness: { scope: [:group_id, :project_id] }

  # we validate the description against DESCRIPTION_LENGTH_MAX only for labels being created and on updates if
  # the description changes to avoid breaking the existing labels which may have their descriptions longer
  validates :description, bytesize: { maximum: -> { DESCRIPTION_LENGTH_MAX } }, if: :validate_description_length?

  default_scope { order(title: :asc) } # rubocop:disable Cop/DefaultScope

  scope :templates, -> { where(template: true, type: [Label.name, nil]) }
  scope :with_title, ->(title) { where(title: title) }
  scope :with_lists_and_board, -> { joins(lists: :board).merge(List.movable) }
  scope :with_lock_on_merge, -> { where(lock_on_merge: true) }
  scope :on_project_boards, ->(project_id) { with_lists_and_board.where(boards: { project_id: project_id }) }
  scope :on_board, ->(board_id) { with_lists_and_board.where(boards: { id: board_id }) }
  scope :order_name_asc, -> { reorder(title: :asc) }
  scope :order_name_desc, -> { reorder(title: :desc) }
  scope :subscribed_by, ->(user_id) { joins(:subscriptions).where(subscriptions: { user_id: user_id, subscribed: true }) }
  scope :with_preloaded_container, -> { preload(parent_container: :route) }

  scope :top_labels_by_target, ->(target_relation) {
    label_id_column = arel_table[:id]

    # Window aggregation to count labels
    count_by_id = Arel::Nodes::Over.new(
      Arel::Nodes::NamedFunction.new('count', [label_id_column]),
      Arel::Nodes::Window.new.partition(label_id_column)
    ).as('count_by_id')

    select(arel_table[Arel.star], count_by_id)
      .joins(:label_links)
      .merge(LabelLink.where(target: target_relation))
      .reorder(count_by_id: :desc)
      .distinct
  }

  scope :for_targets, ->(target_relation) do
    joins(:label_links)
      .merge(LabelLink.where(target: target_relation))
      .select(arel_table[Arel.star], LabelLink.arel_table[:target_id], LabelLink.arel_table[:target_type])
      .with_preloaded_container
  end

  scope :sorted_by_similarity_desc, ->(search) do
    order_expression = Gitlab::Database::SimilarityScore.build_expression(
      search: search,
      rules: [
        { column: arel_table["title"], multiplier: 1 },
        { column: arel_table["description"], multiplier: 0.2 }
      ])

    order = Gitlab::Pagination::Keyset::Order.build(
      [
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'similarity',
          column_expression: order_expression,
          order_expression: order_expression.desc,
          order_direction: :desc,
          add_to_projections: true
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: Label.arel_table[:id].desc
        )
      ])

    order.apply_cursor_conditions(reorder(order))
  end

  def self.pluck_titles
    pluck(:title)
  end

  def self.prioritized(project)
    joins(:priorities)
      .where(label_priorities: { project_id: project })
      .reorder('label_priorities.priority ASC, labels.title ASC')
  end

  def self.unprioritized(project)
    labels = Label.arel_table
    priorities = LabelPriority.arel_table

    label_priorities = labels.join(priorities, Arel::Nodes::OuterJoin)
                              .on(labels[:id].eq(priorities[:label_id]).and(priorities[:project_id].eq(project.id)))
                              .join_sources

    joins(label_priorities).where(priorities[:priority].eq(nil))
  end

  def self.left_join_priorities
    labels = Label.arel_table
    priorities = LabelPriority.arel_table

    label_priorities = labels.join(priorities, Arel::Nodes::OuterJoin)
                              .on(labels[:id].eq(priorities[:label_id]))
                              .join_sources

    joins(label_priorities)
  end

  def self.optionally_subscribed_by(user_id)
    if user_id
      subscribed_by(user_id)
    else
      all
    end
  end

  alias_attribute :name, :title

  def self.reference_prefix
    '~'
  end

  ##
  # Pattern used to extract label references from text
  #
  # This pattern supports cross-project references.
  #
  def self.reference_pattern
    # NOTE: The id pattern only matches when all characters on the expression
    # are digits, so it will match ~2 but not ~2fa because that's probably a
    # label name and we want it to be matched as such.
    @reference_pattern ||= %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}
      (?:
          (?<label_id>\d+(?!\S\w)\b)
        | # Integer-based label ID, or
          (?<label_name>
              # String-based single-word label title, or
              #{Gitlab::Regex.sep_by_1(/:{1,2}/, /[A-Za-z0-9_\-\?\.&]+/)}
              (?<!\.|\?)
            |
              # String-based multi-word label surrounded in quotes
              ".+?"
          )
      )
    }x
  end

  def self.link_reference_pattern
    nil
  end

  def self.ids_on_board(board_id)
    on_board(board_id).pluck(:label_id)
  end

  def self.on_project_board?(project_id, label_id)
    return false if label_id.blank?

    on_project_boards(project_id).where(id: label_id).exists?
  end

  def open_issues_count(user = nil)
    issues_count(user, state: 'opened')
  end

  def closed_issues_count(user = nil)
    issues_count(user, state: 'closed')
  end

  def open_merge_requests_count(user = nil)
    params = {
      subject_foreign_key => subject.id,
      label_name: title,
      scope: 'all',
      state: 'opened'
    }

    MergeRequestsFinder.new(user, params.with_indifferent_access).execute.count
  end

  def prioritize!(project, value)
    label_priority = priorities.find_or_initialize_by(project_id: project.id)
    label_priority.priority = value
    label_priority.save!
  end

  def unprioritize!(project)
    priorities.where(project: project).delete_all
  end

  def priority(project)
    priority = if priorities.loaded?
                 priorities.first { |p| p.project == project }
               else
                 priorities.find_by(project: project)
               end

    priority.try(:priority)
  end

  def priority?
    priorities.present?
  end

  ##
  # Returns the String necessary to reference this Label in Markdown
  #
  # format - Symbol format to use (default: :id, optional: :name)
  #
  # Examples:
  #
  #   Label.first.to_reference                                     # => "~1"
  #   Label.first.to_reference(format: :name)                      # => "~\"bug\""
  #   Label.first.to_reference(project, target_container: same_namespace_project)    # => "gitlab-foss~1"
  #   Label.first.to_reference(project, target_container: another_namespace_project) # => "gitlab-org/gitlab-foss~1"
  #
  # Returns a String
  #
  def to_reference(from = nil, target_container: nil, format: :id, full: false)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if from
      "#{from.to_reference_base(target_container, full: full)}#{reference}"
    else
      reference
    end
  end

  def as_json(options = {})
    super(options).tap do |json|
      json[:type] = self.try(:type)
      json[:priority] = priority(options[:project]) if options.key?(:project)
      json[:textColor] = text_color
    end
  end

  def hook_attrs
    {
      id: id,
      title: title,
      color: color,
      project_id: project_id,
      created_at: created_at,
      updated_at: updated_at,
      template: template,
      description: description,
      type: type,
      group_id: group_id
    }
  end

  def present(attributes = {})
    super(**attributes.merge(presenter_class: ::LabelPresenter))
  end

  private

  def validate_description_length?
    return false unless description_changed?

    previous_description = changes['description'].first
    # previous_description will be nil for new records
    return true if previous_description.blank?

    previous_description.bytesize <= DESCRIPTION_LENGTH_MAX || description.bytesize > previous_description.bytesize
  end

  def issues_count(user, params = {})
    params.merge!(subject_foreign_key => subject.id, label_name: title, scope: 'all')
    IssuesFinder.new(user, params.with_indifferent_access).execute.count
  end

  def label_format_reference(format = :id)
    raise StandardError, 'Unknown format' unless [:id, :name].include?(format)

    if format == :name && name.exclude?('"')
      %("#{name}")
    else
      id
    end
  end

  def prevent_locked_label_destroy
    return unless lock_on_merge

    errors.add(:base, format(_('%{label_name} is locked and was not removed'), label_name: name))
    throw :abort # rubocop:disable Cop/BanCatchThrow
  end

  def ensure_lock_on_merge_allowed
    return unless template?
    return unless lock_on_merge || will_save_change_to_lock_on_merge?

    errors.add(:lock_on_merge, _('can not be set for template labels'))
  end
end

Label.prepend_mod_with('Label')
