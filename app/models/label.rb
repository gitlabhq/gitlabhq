class Label < ActiveRecord::Base
  belongs_to :project
  has_many :label_links, dependent: :destroy
  has_many :issues, through: :label_links, source: :target, source_type: 'Issue'

  validates :color, format: { with: /\A\#[0-9A-Fa-f]{6}+\Z/ }, allow_blank: true
  validates :project, presence: true

  # Dont allow '?', '&', and ',' for label titles
  validates :title,
            presence: true,
            format: { with: /\A[^&\?,&]*\z/ },
            uniqueness: true

  scope :order_by_name, -> { reorder("labels.title ASC") }

  alias_attribute :name, :title

  def open_issues_count
    issues.opened.count
  end
end
