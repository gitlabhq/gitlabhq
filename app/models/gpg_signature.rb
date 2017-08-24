class GpgSignature < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :commit_sha
  sha_attribute :gpg_key_primary_keyid

  enum verification_status: {
    unverified: 0,
    verified: 1,
    other_user: 2,
    unverified_key: 3,
    unknown_key: 4
  }

  belongs_to :project
  belongs_to :gpg_key

  validates :commit_sha, presence: true
  validates :project_id, presence: true
  validates :gpg_key_primary_keyid, presence: true

  def gpg_key_primary_keyid
    super&.upcase
  end

  def commit
    project.commit(commit_sha)
  end

  def gpg_commit
    Gitlab::Gpg::Commit.new(commit)
  end
end
