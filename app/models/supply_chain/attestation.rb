# frozen_string_literal: true

module SupplyChain
  class Attestation < ::ApplicationRecord
    include FileStoreMounter
    include ObjectStorable

    STORE_COLUMN = :file_store

    self.table_name = 'slsa_attestations'

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build', optional: true

    validates :project_id, presence: true
    validates :file, presence: true
    validates :predicate_kind, presence: true
    validates :predicate_type, presence: true
    validates :subject_digest, presence: true, length: { minimum: 64, maximum: 255 }

    validates :subject_digest, uniqueness: { scope: [:project_id, :predicate_kind] }

    attribute :file_store, default: -> { AttestationUploader.default_store }

    mount_file_store_uploader AttestationUploader

    enum :status, {
      success: 0,
      error: 1
    }

    enum :predicate_kind, {
      provenance: 0,
      sbom: 1
    }
  end
end
