# frozen_string_literal: true

module Ci
  class SecureFile < Ci::ApplicationRecord
    include FileStoreMounter
    include Limitable

    FILE_SIZE_LIMIT = 5.megabytes.freeze
    CHECKSUM_ALGORITHM = 'sha256'

    self.limit_scope = :project
    self.limit_name = 'project_ci_secure_files'

    belongs_to :project, optional: false

    validates :file, presence: true, file_size: { maximum: FILE_SIZE_LIMIT }
    validates :checksum, :file_store, :name, :permissions, :project_id, presence: true
    validates :name, uniqueness: { scope: :project }

    after_initialize :generate_key_data
    before_validation :assign_checksum

    enum permissions: { read_only: 0, read_write: 1, execute: 2 }

    default_value_for(:file_store) { Ci::SecureFileUploader.default_store }

    mount_file_store_uploader Ci::SecureFileUploader

    def checksum_algorithm
      CHECKSUM_ALGORITHM
    end

    private

    def assign_checksum
      self.checksum = file.checksum if file.present? && file_changed?
    end

    def generate_key_data
      return if key_data.present?

      self.key_data = SecureRandom.hex(64)
    end
  end
end
