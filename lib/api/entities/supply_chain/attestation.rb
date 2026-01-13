# frozen_string_literal: true

module API
  module Entities
    module SupplyChain
      class Attestation < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :iid, documentation: { type: 'Integer', example: 14 }
        expose :created_at, documentation: { type: 'DateTime', example: '2025-09-17T02:26:10.898Z' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2025-09-17T02:26:10.898Z' }
        expose :expire_at, documentation: { type: 'DateTime', example: '2025-09-17T02:26:10.898Z' }

        expose :project_id, documentation: { type: 'Integer' }
        expose :build_id, documentation: { type: 'Integer' }
        expose :status, documentation: { type: 'String', example: 'success' }
        expose :predicate_kind, documentation: { type: 'String', example: 'provenance' }
        expose :predicate_type, documentation: { type: 'String', example: 'https://slsa.dev/provenance/v1' }
        expose :subject_digest,
          documentation: { type: 'String', example: '5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa' }

        expose :download_url do |attestation|
          expose_url(api_v4_projects_attestations_download_path(id: attestation.project_id, attestation_iid:
                                                                attestation.iid))
        end
      end
    end
  end
end
