class Geo::ProjectRegistry < Geo::BaseRegistry
  belongs_to :project

  validates :project, presence: true

  scope :failed, -> { where.not(last_repository_synced_at: nil).where(last_repository_successful_sync_at: nil) }
  scope :synced, -> { where.not(last_repository_synced_at: nil, last_repository_successful_sync_at: nil) }
end
