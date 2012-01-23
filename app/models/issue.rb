class Issue < ActiveRecord::Base
  belongs_to :project
  belongs_to :author, :class_name => "User"
  belongs_to :assignee, :class_name => "User"
  has_many :notes, :as => :noteable, :dependent => :destroy

  attr_protected :author, :author_id, :project, :project_id

  validates_presence_of :project_id
  validates_presence_of :assignee_id
  validates_presence_of :author_id

  delegate :name,
           :email,
           :to => :author,
           :prefix => true

  delegate :name,
           :email,
           :to => :assignee,
           :prefix => true

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  scope :critical, where(:critical => true)
  scope :non_critical, where(:critical => false)

  scope :opened, where(:closed => false)
  scope :closed, where(:closed => true)
  scope :assigned, lambda { |u| where(:assignee_id => u.id)}

  acts_as_list

  def self.open_for(user)
    opened.assigned(user)
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end
end
# == Schema Information
#
# Table name: issues
#
#  id          :integer         not null, primary key
#  title       :string(255)
#  assignee_id :integer
#  author_id   :integer
#  project_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#  closed      :boolean         default(FALSE), not null
#  position    :integer         default(0)
#  critical    :boolean         default(FALSE), not null
#  branch_name :string(255)
#

