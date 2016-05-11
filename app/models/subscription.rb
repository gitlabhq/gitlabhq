class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :subscribable, polymorphic: true

  validates :user_id,
            uniqueness: { scope: [:subscribable_id, :subscribable_type] },
            presence: true
end
