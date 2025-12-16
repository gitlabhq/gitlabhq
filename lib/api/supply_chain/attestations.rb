# frozen_string_literal: true

module API
  module SupplyChain
    class Attestations < ::API::Base
      include PaginationParams

      feature_category :artifact_security
      urgency :low

      before do
        not_found! unless Feature.enabled?(:slsa_provenance_statement, user_project)
        authorize_read_attestations!
      end

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
      end
      resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Fetch the list of all attestations for a specific project and artifact hash' do
          detail 'This feature was introduced in GitLab 18.7' # TODO: update when FF is removed
          success ::API::Entities::SupplyChain::Attestation
          failure [
            { code: 404, message: 'Artifact SHA-256 not found' }
          ]
          tags ['attestations']
        end
        params do
          requires :subject_digest, type: String,
            desc: 'The SHA-256 hash of the artifact'
        end
        get ':id/attestations/:subject_digest', urgency: :low, format: false,
          requirements: { subject_digest: /[A-Fa-f0-9]{64}/ } do
          subject_digest = params[:subject_digest]
          attestations = ::SupplyChain::Attestation.for_project(user_project.id).with_digest(subject_digest)

          present paginate(attestations), with: ::API::Entities::SupplyChain::Attestation
        end

        desc 'Fetch a specific bundle by iid' do
          success code: 200
          failure [
            { code: 404, message: 'Artifact SHA-256 not found' }
          ]
          detail 'This feature was introduced in GitLab 18.7' # TODO: update when FF is removed
          tags ['attestations']
        end
        params do
          requires :attestation_iid, types: [String, Integer], desc: 'The iid of the attestation'
        end
        get ':id/attestations/:attestation_iid/download', urgency: :low, format: false do
          attestation = ::SupplyChain::Attestation.for_project(user_project.id).with_iid(params[:attestation_iid]).sole

          content_type 'text/json'
          env['api.format'] = :txt

          present attestation.file.read
        end
      end
    end
  end
end

API::SupplyChain::Attestations.prepend_mod_with('API::SupplyChain::Attestations')
