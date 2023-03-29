# frozen_string_literal: true

# PagesDeployment stores a zip archive containing GitLab Pages web-site
class PagesDeployment < ApplicationRecord
  include EachBatch
  include FileStoreMounter
  include Gitlab::Utils::StrongMemoize

  MIGRATED_FILE_NAME = "_migrated.zip"

  attribute :file_store, :integer, default: -> { ::Pages::DeploymentUploader.default_store }

  belongs_to :project, optional: false
  belongs_to :ci_build, class_name: 'Ci::Build', optional: true

  scope :older_than, -> (id) { where('id < ?', id) }
  scope :migrated_from_legacy_storage, -> { where(file: MIGRATED_FILE_NAME) }
  scope :with_files_stored_locally, -> { where(file_store: ::ObjectStorage::Store::LOCAL) }
  scope :with_files_stored_remotely, -> { where(file_store: ::ObjectStorage::Store::REMOTE) }
  scope :project_id_in, ->(ids) { where(project_id: ids) }

  validates :file, presence: true
  validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
  validates :size, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :file_count, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :file_sha256, presence: true

  before_validation :set_size, if: :file_changed?

  mount_file_store_uploader ::Pages::DeploymentUploader

  skip_callback :save, :after, :store_file!, if: :store_after_commit?
  after_commit :store_file_after_commit!, on: [:create, :update], if: :store_after_commit?

  def migrated?
    file.filename == MIGRATED_FILE_NAME
  end

  def store_after_commit?
    Feature.enabled?(:pages_deploy_upload_file_outside_transaction, project)
  end
  strong_memoize_attr :store_after_commit?

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
