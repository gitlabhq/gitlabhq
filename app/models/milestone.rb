class Milestone < ActiveRecord::Base
  attr_accessible :title, :description, :due_date, :closed

  belongs_to :project
  has_many :issues

  validates_presence_of :title, :project_id

  def self.active
    where("due_date > ? OR due_date IS NULL", Date.today)
  end

  def participants
    User.where(id: issues.pluck(:assignee_id))
  end

  def percent_complete
    ((self.issues.closed.count * 100) / self.issues.count).abs
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
