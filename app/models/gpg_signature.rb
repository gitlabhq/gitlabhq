class GpgSignature < ActiveRecord::Base
  belongs_to :project
  belongs_to :gpg_key

  validates :commit_sha, presence: true
  validates :project, presence: true
  validates :gpg_key_primary_keyid, presence: true

  def commit
    project.commit(commit_sha)
  end
end
