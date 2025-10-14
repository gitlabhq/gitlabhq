# frozen_string_literal: true

module SupplyChain
  class Attestation < ::ApplicationRecord
    include AtomicInternalId
    include FileStoreMounter
    include ObjectStorable

    STORE_COLUMN = :file_store

    self.table_name = 'slsa_attestations'

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build', optional: true

    has_internal_id :iid, scope: :project

    validates :project_id, presence: true
    validates :file, presence: true, unless: :error?
    validates :predicate_kind, presence: true
    validates :predicate_type, presence: true
    validates :subject_digest, presence: true, length: { minimum: 64, maximum: 255 }

    validates :subject_digest, uniqueness: { scope: [:project_id, :predicate_kind] }

    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :with_digest, ->(subject_digest) { where(subject_digest: subject_digest) }
    scope :with_predicate_kind, ->(predicate_kind) { where(predicate_kind: predicate_kind) }

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

    def self.find_provenance(project:, subject_digest:)
      for_project(project).with_predicate_kind("provenance").with_digest(subject_digest).take
    end
  end
end
