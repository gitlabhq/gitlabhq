# == Schema Information
#
# Table name: labels
#
#  id           :integer          not null, primary key
#  title        :string(255)
#  color        :string(255)
#  project_id   :integer
#  created_at   :datetime
#  updated_at   :datetime
#  template     :boolean          default(FALSE)
#  description  :string(255)
#

class Label < ActiveRecord::Base
  include Referable
  # Represents a "No Label" state used for filtering Issues and Merge
  # Requests that have no label assigned.
  LabelStruct = Struct.new(:title, :name)
  None = LabelStruct.new('No Label', 'No Label')
  Any = LabelStruct.new('Any Label', '')

  DEFAULT_COLOR = '#428BCA'

  default_value_for :color, DEFAULT_COLOR

  belongs_to :project
  has_many :label_links, dependent: :destroy
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'
  has_many :merge_requests, through: :label_links, source: :target, source_type: 'MergeRequest'

  validates :color, color: true, allow_blank: false
  validates :project, presence: true, unless: Proc.new { |service| service.template? }

  # Don't allow '?', '&', and ',' for label titles
  validates :title,
            presence: true,
            format: { with: /\A[^&\?,]+\z/ },
            uniqueness: { scope: :project_id }

  default_scope { order(title: :asc) }

  scope :templates, ->  { where(template: true) }

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
    %r{
      (#{Project.reference_pattern})?
      #{Regexp.escape(reference_prefix)}
      (?:
        (?<label_id>\d+) | # Integer-based label ID, or
        (?<label_name>
          [A-Za-z0-9_-]+ | # String-based single-word label title, or
          "[^&\?,]+"       # String-based multi-word label surrounded in quotes
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
      project.to_reference + reference
    else
      reference
    end
  end

  def open_issues_count
    issues.opened.count
  end

  def closed_issues_count
    issues.closed.count
  end

  def open_merge_requests_count
    merge_requests.opened.count
  end

  def template?
    template
  end

  private

  def label_format_reference(format = :id)
    raise StandardError, 'Unknown format' unless [:id, :name].include?(format)

    if format == :name && !name.include?('"')
      %("#{name}")
    else
      id
    end
  end
end
