class GroupCustomAttribute < ActiveRecord::Base
  belongs_to :group

  validates :group, :key, :value, presence: true
  validates :key, uniqueness: { scope: [:group_id] }
end
