# frozen_string_literal: true

class LfsObject < ApplicationRecord
  include AfterCommitQueue
  include Checksummable
  include EachBatch
  include ObjectStorage::BackgroundMove

  has_many :lfs_objects_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects, -> { distinct }, through: :lfs_objects_projects

  scope :with_files_stored_locally, -> { where(file_store: LfsObjectUploader::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: LfsObjectUploader::Store::REMOTE) }

  validates :oid, presence: true, uniqueness: true

  mount_uploader :file, LfsObjectUploader

  after_save :update_file_store, if: :saved_change_to_file?

  def self.not_linked_to_project(project)
    where('NOT EXISTS (?)',
          project.lfs_objects_projects.select(1).where('lfs_objects_projects.lfs_object_id = lfs_objects.id'))
  end

  def update_file_store
    # The file.object_store is set during `uploader.store!`
    # which happens after object is inserted/updated
    self.update_column(:file_store, file.object_store)
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

  # rubocop: disable DestroyAll
  def self.destroy_unreferenced
    joins("LEFT JOIN lfs_objects_projects ON lfs_objects_projects.lfs_object_id = #{table_name}.id")
        .where(lfs_objects_projects: { id: nil })
        .destroy_all
  end
  # rubocop: enable DestroyAll

  def self.calculate_oid(path)
    self.hexdigest(path)
  end
end

LfsObject.prepend_if_ee('EE::LfsObject')
