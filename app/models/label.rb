class Label < ActiveRecord::Base
  belongs_to :project
  has_many :label_links, dependent: :destroy

  validates :color, format: { with: /\A\#[0-9A-Fa-f]{3}{1,2}+\Z/ }, allow_blank: true
  validates :project, presence: true
  validates :title, presence: true

  def name
    title
  end
end
