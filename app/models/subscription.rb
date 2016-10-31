class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :subscribable, polymorphic: true

  validates :user, :project, :subscribable, presence: true

  validates :project_id,
            uniqueness: { scope: [:subscribable_id, :subscribable_type, :user_id] },
            presence: true
end
