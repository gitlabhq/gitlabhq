class ProjectRepositoryState < ActiveRecord::Base
  include IgnorableColumn
  include ShaAttribute

  ignore_column :last_repository_verification_at
  ignore_column :last_repository_verification_failed
  ignore_column :last_wiki_verification_at
  ignore_column :last_wiki_verification_failed

  sha_attribute :repository_verification_checksum
  sha_attribute :wiki_verification_checksum

  belongs_to :project, inverse_of: :repository_state

  validates :project, presence: true, uniqueness: true

  scope :verification_failed_repos, -> { where.not(last_repository_verification_failure: nil) }
  scope :verification_failed_wikis, -> { where.not(last_wiki_verification_failure: nil) }
  scope :verified_repos, -> { where.not(repository_verification_checksum: nil).where(last_repository_verification_failure: nil) }
  scope :verified_wikis, -> { where.not(wiki_verification_checksum: nil).where(last_wiki_verification_failure: nil) }

  def repository_checksum_outdated?
    repository_verification_checksum.nil?
  end

  def wiki_checksum_outdated?
    return false unless project.wiki_enabled?

    wiki_verification_checksum.nil?
  end
end
