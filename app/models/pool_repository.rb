# frozen_string_literal: true

class PoolRepository < ActiveRecord::Base
  include Shardable

  has_many :member_projects, class_name: 'Project'

  after_create :correct_disk_path

  private

  def correct_disk_path
    update!(disk_path: storage.disk_path)
  end

  def storage
    Storage::HashedProject
      .new(self, prefix: Storage::HashedProject::POOL_PATH_PREFIX)
  end
end
