# == Schema Information
#
# Table name: milestones
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  project_id  :integer          not null
#  description :text
#  due_date    :date
#  closed      :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Milestone < ActiveRecord::Base
  attr_accessible :title, :description, :due_date, :closed, :author_id_of_changes
  attr_accessor :author_id_of_changes

  belongs_to :project
  has_many :issues
  has_many :merge_requests

  scope :active, where(closed: false)
  scope :closed, where(closed: true)

  validates :title, presence: true
  validates :project, presence: true
  validates :closed, inclusion: { in: [true, false] }

  def expired?
    if due_date
      due_date < Date.today
    else
      false
    end
  end

  def participants
    User.where(id: issues.pluck(:assignee_id))
  end

  def open_items_count
    self.issues.opened.count + self.merge_requests.opened.count
  end

  def closed_items_count
    self.issues.closed.count + self.merge_requests.closed.count
  end

  def total_items_count
    self.issues.count + self.merge_requests.count
  end

  def percent_complete
    ((closed_items_count * 100) / total_items_count).abs
  rescue ZeroDivisionError
    100
  end

  def expires_at
    "expires at #{due_date.stamp("Aug 21, 2011")}" if due_date
  end

  def can_be_closed?
    open? && issues.opened.count.zero?
  end

  def is_empty?
    total_items_count.zero?
  end

  def open?
    !closed
  end

  def author_id
    author_id_of_changes
  end
end
