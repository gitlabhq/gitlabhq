class LfsPointer < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true
  validates :blob_oid, presence: true
  validates :lfs_oid, presence: true
end
