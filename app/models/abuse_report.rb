class AbuseReport < ActiveRecord::Base
  belongs_to :reporter, class_name: "User"
  belongs_to :user

  validates :reporter, presence: true
  validates :user, presence: true
  validates :message, presence: true
  validates :user_id, uniqueness: { scope: :reporter_id }
end
