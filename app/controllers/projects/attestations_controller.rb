# frozen_string_literal: true

module Projects
  class AttestationsController < Projects::ApplicationController
    include SendFileUpload

    feature_category :artifact_security

    before_action :authorize_read_attestation!, only: [:download]

    def download
      return render_404 unless Feature.enabled?(:slsa_provenance_statement, project)
      return render_404 unless attestation_file

      send_upload(attestation_file, attachment: attestation_file.filename)
    end

    private

    def attestation
      @attestation ||= SupplyChain::Attestation.find_by_project_id_and_iid(project.id, safe_params[:id])
    end

    def attestation_file
      attestation&.file
    end

    def authorize_read_attestation!
      access_denied! unless can?(current_user, :read_attestation, project)
    end
  end
end
