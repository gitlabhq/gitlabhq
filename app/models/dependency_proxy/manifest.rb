# frozen_string_literal: true

class DependencyProxy::Manifest < ApplicationRecord
  include FileStoreMounter

  belongs_to :group

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true
  validates :digest, presence: true

  mount_file_store_uploader DependencyProxy::FileUploader
end
