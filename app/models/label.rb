# == Schema Information
#
# Table name: labels
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  color      :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class Label < ActiveRecord::Base
  include Referable

  DEFAULT_COLOR = '#428BCA'

  default_value_for :color, DEFAULT_COLOR

  belongs_to :project
  has_many :label_links, dependent: :destroy
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'

  validates :color,
            format: { with: /\A#[0-9A-Fa-f]{6}\Z/ },
            allow_blank: false
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

  # Pattern used to extract label references from text
  def self.reference_pattern
    %r{
      #{reference_prefix}
      (?:
        (?<label_id>\d+) | # Integer-based label ID, or
        (?<label_name>
          [A-Za-z0-9_-]+ | # String-based single-word label title, or
          "[^&\?,]+"       # String-based multi-word label surrounded in quotes
        )
      )
    }x
  end

  # Returns the String necessary to reference this Label in Markdown
  #
  # format - Symbol format to use (default: :id, optional: :name)
  #
  # Note that its argument differs from other objects implementing Referable. If
  # a non-Symbol argument is given (such as a Project), it will default to :id.
  #
  # Examples:
  #
  #   Label.first.to_reference        # => "~1"
  #   Label.first.to_reference(:name) # => "~\"bug\""
  #
  # Returns a String
  def to_reference(format = :id)
    if format == :name && !name.include?('"')
      %(#{self.class.reference_prefix}"#{name}")
    else
      "#{self.class.reference_prefix}#{id}"
    end
  end

  def open_issues_count
    issues.opened.count
  end

  def template?
    template
  end
end
