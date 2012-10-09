class Group < ActiveRecord::Base
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

  def users
    User.joins(:users_projects).where(users_projects: {project_id: project_ids}).uniq
  end
end

# == Schema Information
#
# Table name: groups
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  code       :string(255)     not null
#  owner_id   :integer         not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

