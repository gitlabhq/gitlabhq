class ProjectRepositoryState < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :repository_verification_checksum
  sha_attribute :wiki_verification_checksum

  belongs_to :project, inverse_of: :repository_state

  validates :project, presence: true, uniqueness: true

  scope :verification_failed_repos, -> { where(arel_table[:last_repository_verification_failed].eq(true)) }
  scope :verification_failed_wikis, -> { where(arel_table[:last_wiki_verification_failed].eq(true)) }

  def repository_checksum_outdated?(timestamp)
    repository_verification_checksum.nil? || recalculate_repository_checksum?(timestamp)
  end

  def wiki_checksum_outdated?(timestamp)
    return false unless project.wiki_enabled?

    wiki_verification_checksum.nil? || recalculate_wiki_checksum?(timestamp)
  end

  def self.verified_repos
    where.not(repository_verification_checksum: nil)
    .where(last_repository_verification_failed: false)
  end

  def self.verified_wikis
    where.not(wiki_verification_checksum: nil)
    .where(last_wiki_verification_failed: false)
  end

  def recalculate_repository_checksum?(timestamp)
    last_repository_verification_at.nil? || timestamp > last_repository_verification_at
  end

  def recalculate_wiki_checksum?(timestamp)
    last_wiki_verification_at.nil? || timestamp > last_wiki_verification_at
  end
end
