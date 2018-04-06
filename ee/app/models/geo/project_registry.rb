class Geo::ProjectRegistry < Geo::BaseRegistry
  include ::EachBatch
  include ::IgnorableColumn
  include ::ShaAttribute

  ignore_column :last_repository_verification_at
  ignore_column :last_repository_verification_failed
  ignore_column :last_wiki_verification_at
  ignore_column :last_wiki_verification_failed
  ignore_column :repository_verification_checksum
  ignore_column :wiki_verification_checksum

  sha_attribute :repository_verification_checksum_sha
  sha_attribute :wiki_verification_checksum_sha

  belongs_to :project

  validates :project, presence: true, uniqueness: true

  scope :dirty, -> { where(arel_table[:resync_repository].eq(true).or(arel_table[:resync_wiki].eq(true))) }
  scope :synced_repos, -> { where(resync_repository: false) }
  scope :synced_wikis, -> { where(resync_wiki: false) }
  scope :failed_repos, -> { where(arel_table[:repository_retry_count].gt(0)) }
  scope :failed_wikis, -> { where(arel_table[:wiki_retry_count].gt(0)) }
  scope :verified_repos, -> { where.not(repository_verification_checksum_sha: nil) }
  scope :verified_wikis, -> { where.not(wiki_verification_checksum_sha: nil) }
  scope :verification_failed_repos, -> { where.not(last_repository_verification_failure: nil) }
  scope :verification_failed_wikis, -> { where.not(last_wiki_verification_failure: nil) }

  def self.failed
    repository_sync_failed = arel_table[:repository_retry_count].gt(0)
    wiki_sync_failed = arel_table[:wiki_retry_count].gt(0)

    where(repository_sync_failed.or(wiki_sync_failed))
  end

  def self.verification_failed
    repository_verification_failed = arel_table[:last_repository_verification_failure].not_eq(nil)
    wiki_verification_failed = arel_table[:last_wiki_verification_failure].not_eq(nil)

    where(repository_verification_failed.or(wiki_verification_failed))
  end

  def self.retry_due
    where(
      arel_table[:repository_retry_at].lt(Time.now)
        .or(arel_table[:wiki_retry_at].lt(Time.now))
        .or(arel_table[:repository_retry_at].eq(nil))
        .or(arel_table[:wiki_retry_at].eq(nil))
    )
  end

  def repository_sync_due?(scheduled_time)
    never_synced_repository? || repository_sync_needed?(scheduled_time)
  end

  def wiki_sync_due?(scheduled_time)
    project.wiki_enabled? && (never_synced_wiki? || wiki_sync_needed?(scheduled_time))
  end

  private

  def never_synced_repository?
    last_repository_synced_at.nil?
  end

  def never_synced_wiki?
    last_wiki_synced_at.nil?
  end

  def repository_sync_needed?(timestamp)
    return false unless resync_repository?
    return false if repository_retry_at && timestamp < repository_retry_at

    last_repository_synced_at && timestamp > last_repository_synced_at
  end

  def wiki_sync_needed?(timestamp)
    return false unless resync_wiki?
    return false if wiki_retry_at && timestamp < wiki_retry_at

    last_wiki_synced_at && timestamp > last_wiki_synced_at
  end
end
