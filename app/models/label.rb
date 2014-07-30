class Label < ActiveRecord::Base
  belongs_to :project
  has_many :label_links, dependent: :destroy

  validates :color, format: { with: /\A\#[0-9A-Fa-f]{6}+\Z/ }, allow_blank: true
  validates :project, presence: true

  # Dont allow '?', '&', and ',' for label titles
  validates :title, presence: true, format: { with: /\A[^&\?,&]*\z/ }

  def name
    title
  end
end
