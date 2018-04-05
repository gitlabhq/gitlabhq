class Label < ActiveRecord::Base
  include CacheMarkdownField
  include Referable
  include Subscribable

  # Represents a "No Label" state used for filtering Issues and Merge
  # Requests that have no label assigned.
  LabelStruct = Struct.new(:title, :name)
  None = LabelStruct.new('No Label', 'No Label')
  Any = LabelStruct.new('Any Label', '')

  cache_markdown_field :description, pipeline: :single_line

  DEFAULT_COLOR = '#428BCA'.freeze

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

  default_scope { order(title: :asc) }

  scope :templates, -> { where(template: true) }
  scope :with_title, ->(title) { where(title: title) }
  scope :with_lists_and_board, -> { joins(lists: :board).merge(List.movable) }
  scope :on_group_boards, ->(group_id) { with_lists_and_board.where(boards: { group_id: group_id }) }
  scope :on_project_boards, ->(project_id) { with_lists_and_board.where(boards: { project_id: project_id }) }

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
        (?<label_id>\d+(?!\S\w)\b) | # Integer-based label ID, or
        (?<label_name>
          [A-Za-z0-9_\-\?\.&]+ | # String-based single-word label title, or
          ".+?"                  # String-based multi-word label surrounded in quotes
        )
      )
    }x
  end

  def self.link_reference_pattern
    nil
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

  def template?
    template
  end

  def color
    super || DEFAULT_COLOR
  end

  def text_color
    LabelsHelper.text_color_for_bg(self.color)
  end

  def title=(value)
    write_attribute(:title, sanitize_title(value)) if value.present?
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
  #   Label.first.to_reference(project, target_project: same_namespace_project)    # => "gitlab-ce~1"
  #   Label.first.to_reference(project, target_project: another_namespace_project) # => "gitlab-org/gitlab-ce~1"
  #
  # Returns a String
  #
  def to_reference(from = nil, target_project: nil, format: :id, full: false)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if from
      "#{from.to_reference(target_project, full: full)}#{reference}"
    else
      reference
    end
  end

  def as_json(options = {})
    super(options).tap do |json|
      json[:type] = self.try(:type)
      json[:priority] = priority(options[:project]) if options.key?(:project)
    end
  end

  def hook_attrs
    attributes
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

  def sanitize_title(value)
    CGI.unescapeHTML(Sanitize.clean(value.to_s))
  end

  def strip_whitespace_from_title_and_color
    %w(color title).each { |attr| self[attr] = self[attr]&.strip }
  end
end
