# frozen_string_literal: true

module SupplyChain
  class Attestation < ::ApplicationRecord
    self.table_name = 'slsa_attestations'

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build', optional: true

    validates :project_id, presence: true
    validates :predicate_kind, presence: true
    validates :predicate_type, presence: true
    validates :subject_digest, presence: true, length: { minimum: 64, maximum: 255 }

    validates :subject_digest, uniqueness: { scope: [:project_id, :predicate_kind] }

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
