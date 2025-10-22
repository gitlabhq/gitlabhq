# frozen_string_literal: true

module API
  module SupplyChain
    class Attestations < ::API::Base
      include PaginationParams

      feature_category :artifact_security
      urgency :low

      before do
        project = find_project!(params[:id])

        not_found! unless Feature.enabled?(:slsa_provenance_statement, project)
        authorize_read_attestations!
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Fetch the list of all attestations for a specific project and artifact hash' do
          detail 'This feature was introduced in GitLab 18.5' # TODO: update when FF is removed
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Artifact not found' }
          ]
        end
        params do
          requires :subject_digest, type: String,
            desc: 'The SHA-256 hash of the artifact'
        end
        get ':id/attestations/:subject_digest',
          urgency: :low, format: false, requirements: { subject_digest: /[A-Fa-f0-9]{64}/ } do
            subject_digest = params[:subject_digest]
            project = find_project!(params[:id])

            attestations = ::SupplyChain::Attestation.for_project(project.id).with_digest(subject_digest)

            present paginate(attestations), with: ::API::Entities::SupplyChain::Attestation
          end
      end
    end
  end
end

API::SupplyChain::Attestations.prepend_mod_with('API::SupplyChain::Attestations')
