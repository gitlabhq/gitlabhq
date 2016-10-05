class UserActivity < ActiveRecord::Base
  belongs_to :user, inverse_of: :user_activity

  validates :user, uniqueness: true, presence: true
  validates :last_activity_at, presence: true

  # Updated version of http://apidock.com/rails/ActiveRecord/Timestamp/touch
  # That accepts a new record.
  def touch
    current_time = current_time_from_proper_timezone

    if persisted?
      update_column(:last_activity_at, current_time)
    else
      self.last_activity_at = current_time
      save!(validate: false)
    end
  end
end
