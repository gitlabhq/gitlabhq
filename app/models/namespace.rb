class Namespace < ActiveRecord::Base
  attr_accessible :code, :name, :owner_id

  has_many :projects
  belongs_to :owner, class_name: "User"

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :owner, presence: true

  delegate :name, to: :owner, allow_nil: true, prefix: true

  def self.search query
    where("name LIKE :query OR code LIKE :query", query: "%#{query}%")
  end

  def to_param
    code
  end

  def human_name
    owner_name
  end
end
