class Milestone < ActiveRecord::Base
  attr_accessible :title, :description, :due_date, :closed

  belongs_to :project
  has_many :issues
  has_many :merge_requests

  validates :title, presence: true
  validates :project, presence: true

  def self.active
    where("due_date > ? OR due_date IS NULL", Date.today)
  end

  def participants
    User.where(id: issues.pluck(:assignee_id))
  end

  def issues_percent_complete
    ((self.issues.closed.count * 100) / self.issues.count).abs
  end

  def merge_requests_percent_complete
    ((self.merge_requests.closed.count * 100) / self.merge_requests.count).abs
  end

  def percent_complete
    (issues_percent_complete + merge_requests_percent_complete) / 2
  rescue ZeroDivisionError
    100
  end

  def expires_at
    "expires at #{due_date.stamp("Aug 21, 2011")}" if due_date
  end
end

# == Schema Information
#
# Table name: milestones
#
#  id          :integer         not null, primary key
#  title       :string(255)     not null
#  project_id  :integer         not null
#  description :text
#  due_date    :date
#  closed      :boolean         default(FALSE), not null
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#

