class Geo::ProjectRegistry < Geo::BaseRegistry
  belongs_to :project

  validates :project, presence: true, uniqueness: true

  scope :dirty, -> { where(arel_table[:resync_repository].eq(true).or(arel_table[:resync_wiki].eq(true))) }

  def self.failed
    repository_sync_failed = arel_table[:last_repository_synced_at].not_eq(nil)
      .and(arel_table[:last_repository_successful_sync_at].eq(nil))

    wiki_sync_failed = arel_table[:last_wiki_synced_at].not_eq(nil)
      .and(arel_table[:last_wiki_successful_sync_at].eq(nil))

    where(repository_sync_failed.or(wiki_sync_failed))
  end

  def self.synced
    where.not(last_repository_synced_at: nil, last_repository_successful_sync_at: nil)
      .where(resync_repository: false, resync_wiki: false)
  end

  def repository_sync_due?(scheduled_time)
    never_synced_repository? || repository_sync_needed?(scheduled_time)
  end

  def wiki_sync_due?(scheduled_time)
    project.wiki_enabled? && (never_synced_wiki? || wiki_sync_needed?(scheduled_time))
  end

  private

  def never_synced_repository?
    last_repository_successful_sync_at.nil?
  end

  def never_synced_wiki?
    last_wiki_successful_sync_at.nil?
  end

  def repository_sync_needed?(timestamp)
    resync_repository? && (last_repository_synced_at.nil? || timestamp > last_repository_synced_at)
  end

  def wiki_sync_needed?(timestamp)
    resync_wiki? && (last_wiki_synced_at.nil? || timestamp > last_wiki_synced_at)
  end
end
