# frozen_string_literal: true

class PoolRepository < ActiveRecord::Base
  belongs_to :shard
  validates :shard, presence: true

  has_many :member_projects, class_name: 'Project'

  after_create :correct_disk_path

  def shard_name
    shard&.name
  end

  def shard_name=(name)
    self.shard = Shard.by_name(name)
  end

  private

  def correct_disk_path
    update!(disk_path: storage.disk_path)
  end

  def storage
    Storage::HashedProject
      .new(self, prefix: Storage::HashedProject::POOL_PATH_PREFIX)
  end
end
