class Geo::ProjectRegistry < Geo::BaseRegistry
  belongs_to :project

  validates :project, presence: true

  scope :dirty, -> { where(arel_table[:resync_repository].eq(true).or(arel_table[:resync_wiki].eq(true))) }
  scope :failed, -> { where.not(last_repository_synced_at: nil).where(last_repository_successful_sync_at: nil) }

  def self.synced
    where.not(last_repository_synced_at: nil, last_repository_successful_sync_at: nil)
      .where(resync_repository: false, resync_wiki: false)
  end

  def resync_repository?
    resync_repository || last_repository_successful_sync_at.nil?
  end

  def resync_wiki?
    resync_wiki || last_wiki_successful_sync_at.nil?
  end

  def repository_synced_since?(timestamp)
    last_repository_synced_at && last_repository_synced_at > timestamp
  end

  def wiki_synced_since?(timestamp)
    last_wiki_synced_at && last_wiki_synced_at > timestamp
  end
end
