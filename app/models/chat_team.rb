class ChatTeam < ApplicationRecord
  validates :team_id, presence: true
  validates :namespace, uniqueness: true

  belongs_to :namespace
end
