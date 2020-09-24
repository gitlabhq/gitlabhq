# frozen_string_literal: true

# PagesDeployment stores a zip archive containing GitLab Pages web-site
class PagesDeployment < ApplicationRecord
  include FileStoreMounter

  belongs_to :project, optional: false
  belongs_to :ci_build, class_name: 'Ci::Build', optional: true

  validates :file, presence: true
  validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
  validates :size, presence: true, numericality: { greater_than: 0, only_integer: true }

  mount_file_store_uploader ::Pages::DeploymentUploader
end
