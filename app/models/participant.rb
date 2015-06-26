class Participant < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, polymorphic: true

  validates :user_id,
            uniqueness: { scope: [:target_id, :target_type] },
            presence: true
end
