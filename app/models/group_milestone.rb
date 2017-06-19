class GroupMilestone < ActiveRecord::Base
  include StripAttribute

  has_many :issues
  has_many :merge_requests

  # Use a uniqueness scope here to check name with project milestones
  validates :title, presence: true

  # Move this validation to a concern and share with project milestone
  validate :start_date_should_be_less_than_due_date, if: proc { |m| m.start_date.present? && m.due_date.present? }
  strip_attributes :title
  alias_attribute :name, :title


  def start_date_should_be_less_than_due_date
    if due_date <= start_date
      errors.add(:start_date, "Can't be greater than due date")
    end
  end
end
