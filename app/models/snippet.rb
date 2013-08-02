# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text(2147483647)
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  file_name  :string(255)
#  expires_at :datetime
#  type       :string(255)
#  visibility :string(255)      not null
#

class Snippet < ActiveRecord::Base
  include Linguist::BlobHelper

  attr_accessible :title, :content, :file_name, :expires_at, :visibility

  belongs_to :author, class_name: "User"

  has_many :notes, as: :noteable, dependent: :destroy

  delegate :name, :email, to: :author, prefix: true, allow_nil: true

  validates :author, presence: true
  validates :title, presence: true, length: { within: 0..255 }
  validates :file_name, presence: true, length: { within: 0..255 }
  validates :content, presence: true

  # Scopes
  scope :gitlab_public, -> { where(visibility: :gitlab_public) }
  scope :world_public,  -> { where(visibility: :world_public) }
  scope :private,       -> { where(visibility: :private) }
  scope :all_public,    -> { where("visibility IN (?)", [:gitlab_public, :world_public]) }
  scope :fresh,         -> { order("created_at DESC") }
  scope :expired,       -> { where(["expires_at IS NOT NULL AND expires_at < ?", Time.current]) }
  scope :non_expired,   -> { where(["expires_at IS NULL OR expires_at > ?", Time.current]) }

  def self.content_types
    [
      ".rb", ".py", ".pl", ".scala", ".c", ".cpp", ".java",
      ".haml", ".html", ".sass", ".scss", ".xml", ".php", ".erb",
      ".js", ".sh", ".coffee", ".yml", ".md"
    ]
  end

  def data
    content
  end

  def size
    0
  end

  def name
    file_name
  end

  def mode
    nil
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  %w{private gitlab_public world_public}.each do |visibility_type|
    define_method "#{visibility_type}?" do
      visibility.to_s == visibility_type
    end
  end
end
