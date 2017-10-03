class UnprocessedLfsPush < ActiveRecord::Base
  belongs_to :project

  validates :project, presence: true
  validates :newrev, presence: true
  validates :ref, presence: true

  def processed!
    transaction do
      project.processed_lfs_refs.find_or_create_by(ref: ref)

      self.destroy!
    end
  end
end
