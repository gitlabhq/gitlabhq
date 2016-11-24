class ChatName < ActiveRecord::Base
  belongs_to :service
  belongs_to :user

  validates :user, presence: true
  validates :service, presence: true
  validates :team_id, presence: true
  validates :chat_id, presence: true

  validates :user_id, uniqueness: { scope: [:service_id] }
  validates :chat_id, uniqueness: { scope: [:service_id, :team_id] }
end
