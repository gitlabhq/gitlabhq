class GpgSignature < ActiveRecord::Base
  include ShaAttribute

  sha_attribute :commit_sha
  sha_attribute :gpg_key_primary_keyid

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
    Gitlab::Gpg::Commit.new(project, commit_sha)
  end
end
