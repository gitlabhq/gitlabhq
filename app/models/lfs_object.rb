# frozen_string_literal: true

class LfsObject < ApplicationRecord
  include AfterCommitQueue
  include Checksummable
  include EachBatch
  include ObjectStorage::BackgroundMove
  include FileStoreMounter

  has_many :lfs_objects_projects
  has_many :projects, -> { distinct }, through: :lfs_objects_projects

  scope :with_files_stored_locally, -> { where(file_store: LfsObjectUploader::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: LfsObjectUploader::Store::REMOTE) }
  scope :for_oids, -> (oids) { where(oid: oids) }

  validates :oid, presence: true, uniqueness: true

  mount_file_store_uploader LfsObjectUploader

  BATCH_SIZE = 3000

  def self.not_linked_to_project(project)
    where('NOT EXISTS (?)',
          project.lfs_objects_projects.select(1).where('lfs_objects_projects.lfs_object_id = lfs_objects.id'))
  end

  def project_allowed_access?(project)
    if project.fork_network_member
      lfs_objects_projects
        .where("EXISTS(?)", project.fork_network.fork_network_members.select(1).where("fork_network_members.project_id = lfs_objects_projects.project_id"))
        .exists?
    else
      lfs_objects_projects.where(project_id: project.id).exists?
    end
  end

  def local_store?
    file_store == LfsObjectUploader::Store::LOCAL
  end

  def self.unreferenced_in_batches
    each_batch(of: BATCH_SIZE, order: :desc) do |lfs_objects|
      relation = lfs_objects.where('NOT EXISTS (?)',
              LfsObjectsProject.select(1).where('lfs_objects_projects.lfs_object_id = lfs_objects.id'))

      yield relation if relation.any?
    end
  end

  def self.calculate_oid(path)
    self.hexdigest(path)
  end
end

LfsObject.prepend_mod_with('LfsObject')
