# frozen_string_literal: true

class DependencyProxy::Manifest < ApplicationRecord
  include FileStoreMounter

  belongs_to :group

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true
  validates :digest, presence: true

  mount_file_store_uploader DependencyProxy::FileUploader

  def self.find_or_initialize_by_file_name_or_digest(file_name:, digest:)
    result = find_by(file_name: file_name) || find_by(digest: digest)
    return result if result

    new(file_name: file_name, digest: digest)
  end
end
