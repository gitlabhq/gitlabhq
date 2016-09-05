class Label < ActiveRecord::Base
  include Referable
  include Subscribable

  # Represents a "No Label" state used for filtering Issues and Merge
  # Requests that have no label assigned.
  LabelStruct = Struct.new(:title, :name)
  None = LabelStruct.new('No Label', 'No Label')
  Any = LabelStruct.new('Any Label', '')

  DEFAULT_COLOR = '#428BCA'

  default_value_for :color, DEFAULT_COLOR

  belongs_to :subject, polymorphic: true

  has_many :lists, dependent: :destroy
  has_many :label_links, dependent: :destroy
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'
  has_many :merge_requests, through: :label_links, source: :target, source_type: 'MergeRequest'

  validates :color, color: true, allow_blank: false
  validates :subject, presence: true, unless: Proc.new { |service| service.template? }

  # Don't allow ',' for label titles
  validates :title,
            presence: true,
            format: { with: /\A[^,]+\z/ },
            uniqueness: { scope: :subject_id }

  before_save :nullify_priority

  default_scope { order(title: :asc) }

  scope :templates, ->  { where(template: true) }

  def self.prioritized
    where.not(priority: nil).reorder(:priority, :title)
  end

  def self.unprioritized
    where(priority: nil)
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

  ##
  # Returns the String necessary to reference this Label in Markdown
  #
  # format - Symbol format to use (default: :id, optional: :name)
  #
  # Examples:
  #
  #   Label.first.to_reference                # => "~1"
  #   Label.first.to_reference(format: :name) # => "~\"bug\""
  #   Label.first.to_reference(project)       # => "gitlab-org/gitlab-ce~1"
  #
  # Returns a String
  #
  def to_reference(from_project = nil, format: :id)
    format_reference = label_format_reference(format)
    reference = "#{self.class.reference_prefix}#{format_reference}"

    if cross_project_reference?(from_project)
      subject.to_reference + reference
    else
      reference
    end
  end

  def open_issues_count(user = nil)
    issues.visible_to_user(user).opened.count
  end

  def closed_issues_count(user = nil)
    issues.visible_to_user(user).closed.count
  end

  def open_merge_requests_count
    merge_requests.opened.count
  end

  def template?
    template
  end

  def text_color
    LabelsHelper::text_color_for_bg(self.color)
  end

  def title=(value)
    write_attribute(:title, sanitize_title(value)) if value.present?
  end

  private

  def cross_project_reference?(from_project)
    if self.is_a?(Project)
      self != from_project
    else
      from_project && self.subject && self.subject != from_project
    end
  end

  def label_format_reference(format = :id)
    raise StandardError, 'Unknown format' unless [:id, :name].include?(format)

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      id
    end
  end

  def nullify_priority
    self.priority = nil if priority.blank?
  end

  def sanitize_title(value)
    CGI.unescapeHTML(Sanitize.clean(value.to_s))
  end
end
