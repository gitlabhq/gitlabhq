class Issue < ActiveRecord::Base
  include Upvote

  acts_as_taggable_on :labels

  belongs_to :project
  belongs_to :milestone
  belongs_to :author, :class_name => "User"
  belongs_to :assignee, :class_name => "User"
  has_many :notes, :as => :noteable, :dependent => :destroy

  attr_protected :author, :author_id, :project, :project_id
  attr_accessor :author_id_of_changes

  validates_presence_of :project_id
  validates_presence_of :author_id

  delegate :name,
           :email,
           :to => :author,
           :prefix => true

  delegate :name,
           :email,
           :to => :assignee,
           :allow_nil => true,
           :prefix => true

  validates :title,
            :presence => true,
            :length   => { :within => 0..255 }

  validates :description,
            :length   => { :within => 0..2000 }

  scope :opened, where(:closed => false)
  scope :closed, where(:closed => true)
  scope :assigned, lambda { |u| where(:assignee_id => u.id)}

  acts_as_list

  def self.open_for(user)
    opened.assigned(user)
  end

  def self.search query
    where("title like :query", :query => "%#{query}%")
  end

  def today?
    Date.today == created_at.to_date
  end

  def new?
    today? && created_at == updated_at
  end

  def is_assigned?
    !!assignee_id
  end

  def is_being_reassigned?
    assignee_id_changed?
  end

  def is_being_closed?
    closed_changed? && closed
  end

  def is_being_reopened?
    closed_changed? && !closed
  end
end
# == Schema Information
#
# Table name: issues
#
#  id           :integer(4)      not null, primary key
#  title        :string(255)
#  assignee_id  :integer(4)
#  author_id    :integer(4)
#  project_id   :integer(4)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  closed       :boolean(1)      default(FALSE), not null
#  position     :integer(4)      default(0)
#  critical     :boolean(1)      default(FALSE), not null
#  branch_name  :string(255)
#  description  :text
#  milestone_id :integer(4)
#

