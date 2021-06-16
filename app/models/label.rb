# frozen_string_literal: true

class Label < ApplicationRecord
  include CacheMarkdownField
  include Referable
  include Subscribable
  include Gitlab::SQL::Pattern
  include OptionallySearch
  include Sortable
  include FromUnion
  include Presentable
  include IgnorableColumns

  # TODO: Project#create_labels can remove column exception when this column is dropped from all envs
  ignore_column :remove_on_close, remove_with: '14.1', remove_after: '2021-06-22'

  cache_markdown_field :description, pipeline: :single_line

  DEFAULT_COLOR = '#6699cc'

  default_value_for :color, DEFAULT_COLOR

  has_many :lists, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :priorities, class_name: 'LabelPriority'
  has_many :label_links, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'
  has_many :merge_requests, through: :label_links, source: :target, source_type: 'MergeRequest'

  before_validation :strip_whitespace_from_title_and_color

  validates :color, color: true, allow_blank: false

  # Don't allow ',' for label titles
  validates :title, presence: true, format: { with: /\A[^,]+\z/ }
  validates :title, uniqueness: { scope: [:group_id, :project_id] }
  validates :title, length: { maximum: 255 }

  default_scope { order(title: :asc) } # rubocop:disable Cop/DefaultScope

  scope :templates, -> { where(template: true, type: [Label.name, nil]) }
  scope :with_title, ->(title) { where(title: title) }
  scope :with_lists_and_board, -> { joins(lists: :board).merge(List.movable) }
  scope :on_project_boards, ->(project_id) { with_lists_and_board.where(boards: { project_id: project_id }) }
  scope :on_board, ->(board_id) { with_lists_and_board.where(boards: { id: board_id }) }
  scope :order_name_asc, -> { reorder(title: :asc) }
  scope :order_name_desc, -> { reorder(title: :desc) }
  scope :subscribed_by, ->(user_id) { joins(:subscriptions).where(subscriptions: { user_id: user_id, subscribed: true }) }

  scope :top_labels_by_target, -> (target_relation) {
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
              [A-Za-z0-9_\-\?\.&]+
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

  # Searches for labels with a matching title or description.
  #
  # This method uses ILIKE on PostgreSQL.
  #
  # query - The search query as a String.
  #
  # Returns an ActiveRecord::Relation.
  def self.search(query, **options)
    fuzzy_search(query, [:title, :description])
  end

  # Override Gitlab::SQL::Pattern.min_chars_for_partial_matching as
  # label queries are never global, and so will not use a trigram
  # index. That means we can have just one character in the LIKE.
  def self.min_chars_for_partial_matching
    1
  end

  def self.on_project_board?(project_id, label_id)
    return false if label_id.blank?

    on_project_boards(project_id).where(id: label_id).exists?
  end

  # Generate a hex color based on hex-encoded value
  def self.color_for(value)
    "##{Digest::MD5.hexdigest(value)[0..5]}"
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

  def color
    super || DEFAULT_COLOR
  end

  def text_color
    LabelsHelper.text_color_for_bg(self.color)
  end

  def title=(value)
    write_attribute(:title, sanitize_value(value)) if value.present?
  end

  def description=(value)
    write_attribute(:description, sanitize_value(value)) if value.present?
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
  #   Label.first.to_reference(project, target_project: same_namespace_project)    # => "gitlab-foss~1"
  #   Label.first.to_reference(project, target_project: another_namespace_project) # => "gitlab-org/gitlab-foss~1"
  #
  # Returns a String
  #
  def to_reference(from = nil, target_project: nil, format: :id, full: false)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if from
      "#{from.to_reference_base(target_project, full: full)}#{reference}"
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
    attributes
  end

  def present(attributes)
    super(**attributes.merge(presenter_class: ::LabelPresenter))
  end

  private

  def issues_count(user, params = {})
    params.merge!(subject_foreign_key => subject.id, label_name: title, scope: 'all')
    IssuesFinder.new(user, params.with_indifferent_access).execute.count
  end

  def label_format_reference(format = :id)
    raise StandardError, 'Unknown format' unless [:id, :name].include?(format)

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      id
    end
  end

  def sanitize_value(value)
    CGI.unescapeHTML(Sanitize.clean(value.to_s))
  end

  def strip_whitespace_from_title_and_color
    %w(color title).each { |attr| self[attr] = self[attr]&.strip }
  end
end

Label.prepend_mod_with('Label')
