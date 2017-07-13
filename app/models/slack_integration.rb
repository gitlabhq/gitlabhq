class SlackIntegration < ActiveRecord::Base
  belongs_to :service

  validates :team_id, presence: true
  validates :team_name, presence: true
  validates :alias, presence: true,
                    uniqueness: { scope: :team_id, message: 'This alias has already been taken' },
                    length: 2..80
  validates :user_id, presence: true
  validates :service, presence: true

  after_commit :update_active_status_of_service, on: [:create, :destroy]

  def update_active_status_of_service
    service.update_active_status
  end
end
