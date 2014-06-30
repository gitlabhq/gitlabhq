# == Schema Information
#
# Table name: milestones
#
#  id          :integer          not null, primary key
#  title       :string(255)      not null
#  project_id  :integer          not null
#  description :text
#  due_date    :date
#  created_at  :datetime
#  updated_at  :datetime
#  state       :string(255)
#  iid         :integer
#

class Milestone < ActiveRecord::Base
  include InternalId

  belongs_to :project
  has_many :issues
  has_many :merge_requests
  has_many :participants, through: :issues, source: :assignee

  scope :active, -> { with_state(:active) }
  scope :closed, -> { with_state(:closed) }
  scope :of_projects, ->(ids) { where(project_id: ids) }

  validates :title, presence: true
  validates :project, presence: true

  state_machine :state, initial: :active do
    event :close do
      transition active: :closed
    end

    event :activate do
      transition closed: :active
    end

    state :closed

    state :active
  end

  def expired?
    if due_date
      due_date.past?
    else
      false
    end
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
    if due_date
      if due_date.past?
        "expired at #{due_date.stamp("Aug 21, 2011")}"
      else
        "expires at #{due_date.stamp("Aug 21, 2011")}"
      end
    end
  end

  def can_be_closed?
    active? && issues.opened.count.zero?
  end

  def is_empty?
    total_items_count.zero?
  end

  def author_id
    nil
  end
end
