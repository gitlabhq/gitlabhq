# frozen_string_literal: true

# PagesDeployment stores a zip archive containing GitLab Pages web-site
class PagesDeployment < ApplicationRecord
  include EachBatch
  include FileStoreMounter

  MIGRATED_FILE_NAME = "_migrated.zip"

  attribute :file_store, :integer, default: -> { ::Pages::DeploymentUploader.default_store }

  belongs_to :project, optional: false
  belongs_to :ci_build, class_name: 'Ci::Build', optional: true

  scope :older_than, -> (id) { where('id < ?', id) }
  scope :migrated_from_legacy_storage, -> { where(file: MIGRATED_FILE_NAME) }
  scope :with_files_stored_locally, -> { where(file_store: ::ObjectStorage::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: ::ObjectStorage::Store::REMOTE) }

  validates :file, presence: true
  validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
  validates :size, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :file_count, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :file_sha256, presence: true

  before_validation :set_size, if: :file_changed?

  mount_file_store_uploader ::Pages::DeploymentUploader

  def log_geo_deleted_event
    # this is to be adressed in https://gitlab.com/groups/gitlab-org/-/epics/589
  end

  def migrated?
    file.filename == MIGRATED_FILE_NAME
  end

  private

  def set_size
    self.size = file.size
  end
end
