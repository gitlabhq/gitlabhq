# frozen_string_literal: true

# PagesDeployment stores a zip archive containing GitLab Pages web-site
class PagesDeployment < ApplicationRecord
  include EachBatch
  include FileStoreMounter
  include Gitlab::Utils::StrongMemoize

  MIGRATED_FILE_NAME = "_migrated.zip"

  attribute :file_store, :integer, default: -> { ::Pages::DeploymentUploader.default_store }

  belongs_to :project, optional: false

  # ci_build is optional, because PagesDeployment must live even if its build/pipeline is removed.
  belongs_to :ci_build, class_name: 'Ci::Build', optional: true

  scope :older_than, ->(id) { where('id < ?', id) }
  scope :migrated_from_legacy_storage, -> { where(file: MIGRATED_FILE_NAME) }
  scope :with_files_stored_locally, -> { where(file_store: ::ObjectStorage::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: ::ObjectStorage::Store::REMOTE) }
  scope :project_id_in, ->(ids) { where(project_id: ids) }
  scope :active, -> { where(deleted_at: nil) }
  scope :deactivated, -> { where('deleted_at < ?', Time.now.utc) }

  validates :file, presence: true
  validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
  validates :size, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :file_count, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :file_sha256, presence: true

  before_validation :set_size, if: :file_changed?

  mount_file_store_uploader ::Pages::DeploymentUploader

  skip_callback :save, :after, :store_file!
  after_commit :store_file_after_commit!, on: [:create, :update]

  def self.deactivate_deployments_older_than(deployment, time: nil)
    now = Time.now.utc
    active
      .older_than(deployment.id)
      .where(project_id: deployment.project_id, path_prefix: deployment.path_prefix)
      .update_all(updated_at: now, deleted_at: time || now)
  end

  def migrated?
    file.filename == MIGRATED_FILE_NAME
  end

  private

  def set_size
    self.size = file.size
  end

  def store_file_after_commit!
    return unless previous_changes.key?(:file)

    store_file_now!
  end
end

PagesDeployment.prepend_mod
