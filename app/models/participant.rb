class Participant < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, polymorphic: true

  validates :target_id, presence: true
  validates :target_type, presence: true
  validates :user_id,
            uniqueness: { scope: [:target_id, :target_type] },
            presence: true
end
