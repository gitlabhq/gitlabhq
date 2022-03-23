# frozen_string_literal: true

module Ci
  class SecureFile < Ci::ApplicationRecord
    include FileStoreMounter
    include Limitable

    FILE_SIZE_LIMIT = 5.megabytes.freeze
    CHECKSUM_ALGORITHM = 'sha256'

    self.limit_scope = :project
    self.limit_name = 'project_ci_secure_files'

    attr_accessor :file_checksum

    belongs_to :project, optional: false

    validates :file, presence: true, file_size: { maximum: FILE_SIZE_LIMIT }
    validates :checksum, :file_store, :name, :permissions, :project_id, presence: true
    validate :validate_upload_checksum, on: :create

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

    def validate_upload_checksum
      unless self.file_checksum.nil?
        errors.add(:file_checksum, _("Secure Files|File did not match the provided checksum")) unless self.file_checksum == self.checksum
      end
    end
  end
end
