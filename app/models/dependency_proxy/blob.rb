# frozen_string_literal: true

class DependencyProxy::Blob < ApplicationRecord
  include FileStoreMounter
  include ObjectStorable
  include TtlExpirable
  include Packages::Destructible
  include EachBatch
  include UpdateNamespaceStatistics

  belongs_to :group
  alias_method :namespace, :group

  STORE_COLUMN = :file_store
  MAX_FILE_SIZE = 5.gigabytes.freeze

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true

  mount_file_store_uploader DependencyProxy::FileUploader
  update_namespace_statistics namespace_statistics_name: :dependency_proxy_size

  def self.total_size
    sum(:size)
  end

  def self.find_or_build(file_name)
    find_or_initialize_by(file_name: file_name)
  end
end

DependencyProxy::Blob.prepend_mod_with('DependencyProxy::Blob')
