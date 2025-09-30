# frozen_string_literal: true

module API
  module Entities
    module SupplyChain
      class Attestation < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }

        expose :created_at, documentation: { type: 'dateTime', example: '2025-09-17T02:26:10.898Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2025-09-17T02:26:10.898Z' }
        expose :expire_at, documentation: { type: 'dateTime', example: '2025-09-17T02:26:10.898Z' }

        expose :project_id, documentation: { type: 'integer' }
        expose :build_id, documentation: { type: 'integer' }
        expose :status, documentation: { type: 'string', example: 'success' }
        expose :predicate_kind, documentation: { type: 'string', example: 'provenance' }
        expose :predicate_type, documentation: { type: 'string', example: 'https://slsa.dev/provenance/v1' }
        expose :subject_digest,
          documentation: { type: 'string', example: '5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa' }
      end
    end
  end
end
