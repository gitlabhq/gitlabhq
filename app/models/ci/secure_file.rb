# frozen_string_literal: true

module Ci
  class SecureFile < Ci::ApplicationRecord
    include FileStoreMounter
    include IgnorableColumns
    include Limitable

    ignore_column :permissions, remove_with: '15.2', remove_after: '2022-06-22'

    FILE_SIZE_LIMIT = 5.megabytes.freeze
    CHECKSUM_ALGORITHM = 'sha256'

    self.limit_scope = :project
    self.limit_name = 'project_ci_secure_files'

    belongs_to :project, optional: false

    validates :file, presence: true, file_size: { maximum: FILE_SIZE_LIMIT }
    validates :checksum, :file_store, :name, :project_id, presence: true
    validates :name, uniqueness: { scope: :project }

    after_initialize :generate_key_data
    before_validation :assign_checksum

    scope :order_by_created_at, -> { order(created_at: :desc) }
    scope :project_id_in, ->(ids) { where(project_id: ids) }

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

Ci::SecureFile.prepend_mod
