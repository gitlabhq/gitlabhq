class ChatTeam < ActiveRecord::Base
  validates :team_id, presence: true
  validates :namespace, uniqueness: true

  belongs_to :namespace
end
