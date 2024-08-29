# frozen_string_literal: true

class LfsObject < ApplicationRecord
  include AfterCommitQueue
  include Checksummable
  include EachBatch
  include FileStoreMounter

  has_many :lfs_objects_projects
  has_many :projects, -> { distinct }, through: :lfs_objects_projects

  scope :with_files_stored_locally, -> { where(file_store: LfsObjectUploader::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: LfsObjectUploader::Store::REMOTE) }
  scope :for_oids, ->(oids) { where(oid: oids) }

  validates :oid, presence: true, uniqueness: true, format: { with: /\A\h{64}\z/ }

  mount_file_store_uploader LfsObjectUploader

  BATCH_SIZE = 3000

  def self.for_oid_and_size(oid, size)
    find_by(oid: oid, size: size)
  end

  def self.not_linked_to_project(project, repository_type: nil)
    linked_to_project = project.lfs_objects_projects.where('lfs_objects_projects.lfs_object_id = lfs_objects.id')
    linked_to_project = linked_to_project.where(repository_type: repository_type) if repository_type
    where(
      'NOT EXISTS (?)',
      linked_to_project.select(1)
    )
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
      relation = lfs_objects.where(
        'NOT EXISTS (?)',
        LfsObjectsProject.select(1).where('lfs_objects_projects.lfs_object_id = lfs_objects.id')
      )

      yield relation if relation.any?
    end
  end

  def self.calculate_oid(path)
    self.sha256_hexdigest(path)
  end
end

LfsObject.prepend_mod_with('LfsObject')
