# frozen_string_literal: true

class DependencyProxy::Manifest < ApplicationRecord
  include FileStoreMounter
  include TtlExpirable
  include Packages::Destructible
  include EachBatch
  include UpdateNamespaceStatistics

  belongs_to :group
  alias_attribute :namespace, :group

  MAX_FILE_SIZE = 10.megabytes.freeze
  DIGEST_HEADER = 'Docker-Content-Digest'
  ACCEPTED_TYPES = [
    ContainerRegistry::BaseClient::DOCKER_DISTRIBUTION_MANIFEST_V2_TYPE,
    ContainerRegistry::BaseClient::OCI_MANIFEST_V1_TYPE,
    ContainerRegistry::BaseClient::OCI_DISTRIBUTION_INDEX_TYPE,
    ContainerRegistry::BaseClient::DOCKER_DISTRIBUTION_MANIFEST_LIST_V2_TYPE
  ].freeze

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true
  validates :digest, presence: true

  scope :order_id_desc, -> { reorder(id: :desc) }
  scope :with_files_stored_locally, -> { where(file_store: ::DependencyProxy::FileUploader::Store::LOCAL) }

  mount_file_store_uploader DependencyProxy::FileUploader
  update_namespace_statistics namespace_statistics_name: :dependency_proxy_size

  def self.find_by_file_name_or_digest(file_name:, digest:)
    find_by(file_name: file_name) || find_by(digest: digest)
  end
end

DependencyProxy::Manifest.prepend_mod_with('DependencyProxy::Manifest')
