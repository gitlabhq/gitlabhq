class GpgSignature < ActiveRecord::Base
  belongs_to :project
  belongs_to :gpg_key

  validates :commit_sha, presence: true
  validates :project, presence: true
end
