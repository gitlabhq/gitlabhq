# frozen_string_literal: true

class DependencyProxy::Manifest < ApplicationRecord
  include FileStoreMounter
  include TtlExpirable
  include Packages::Destructible
  include EachBatch

  belongs_to :group

  MAX_FILE_SIZE = 10.megabytes.freeze
  DIGEST_HEADER = 'Docker-Content-Digest'

  validates :group, presence: true
  validates :file, presence: true
  validates :file_name, presence: true
  validates :digest, presence: true

  scope :order_id_desc, -> { reorder(id: :desc) }

  mount_file_store_uploader DependencyProxy::FileUploader

  def self.find_by_file_name_or_digest(file_name:, digest:)
    find_by(file_name: file_name) || find_by(digest: digest)
  end
end
