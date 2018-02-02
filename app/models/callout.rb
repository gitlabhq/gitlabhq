class Callout < ActiveRecord::Base
  belongs_to :user

  validates :user, presence: true
  validates :feature_name, presence: true, uniqueness: { scope: :user_id }
end
