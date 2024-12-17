# frozen_string_literal: true

module Ci
  class SecureFile < Ci::ApplicationRecord
    include FileStoreMounter
    include Limitable

    FILE_SIZE_LIMIT = 5.megabytes.freeze
    CHECKSUM_ALGORITHM = 'sha256'
    PARSABLE_EXTENSIONS = %w[cer p12 mobileprovision].freeze

    self.limit_scope = :project
    self.limit_name = 'project_ci_secure_files'

    belongs_to :project, optional: false

    validates :file, presence: true, file_size: { maximum: FILE_SIZE_LIMIT }
    validates :checksum, :file_store, :name, :project_id, presence: true
    validates :name, uniqueness: { scope: :project }

    attribute :metadata, ::Gitlab::Database::Type::IndifferentJsonb.new
    validates :metadata, json_schema: { filename: "ci_secure_file_metadata" }, allow_nil: true

    attribute :file_store, default: -> { Ci::SecureFileUploader.default_store }
    mount_file_store_uploader Ci::SecureFileUploader

    after_initialize :generate_key_data
    before_validation :assign_checksum

    scope :order_by_created_at, -> { order(created_at: :desc) }
    scope :project_id_in, ->(ids) { where(project_id: ids) }
    scope :with_files_stored_locally, -> { where(file_store: Ci::SecureFileUploader::Store::LOCAL) }

    def checksum_algorithm
      CHECKSUM_ALGORITHM
    end

    def file_extension
      File.extname(name).delete_prefix('.').presence
    end

    def metadata_parsable?
      PARSABLE_EXTENSIONS.include?(file_extension)
    end

    def metadata_parser
      return unless metadata_parsable?

      case file_extension
      when 'cer'
        Gitlab::Ci::SecureFiles::Cer.new(file.read)
      when 'p12'
        Gitlab::Ci::SecureFiles::P12.new(file.read) if Feature.enabled?(:secure_files_p12_parser)
      when 'mobileprovision'
        Gitlab::Ci::SecureFiles::MobileProvision.new(file.read)
      end
    end

    def update_metadata!
      return unless metadata_parser

      begin
        parser = metadata_parser
        self.metadata = parser.metadata
        self.expires_at = parser.metadata[:expires_at]
        save!
      rescue StandardError => err
        Gitlab::AppLogger.error("Secure File Parser Failure (#{id}): #{err.message} - #{parser.error}.")
        nil
      end
    end

    def local?
      file_store == ObjectStorage::Store::LOCAL
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
