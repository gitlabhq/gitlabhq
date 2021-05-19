# frozen_string_literal: true

module Releases
  class CreateEvidenceService
    def initialize(release, pipeline: nil)
      @release = release
      @pipeline = pipeline
    end

    def execute
      evidence = release.evidences.build

      summary = ::Evidences::EvidenceSerializer.new.represent(evidence, evidence_options) # rubocop: disable CodeReuse/Serializer
      evidence.summary = summary
      # TODO: fix the sha generation https://gitlab.com/groups/gitlab-org/-/epics/3683
      evidence.summary_sha = Gitlab::CryptoHelper.sha256(summary)

      evidence.save!
    end

    private

    attr_reader :release, :pipeline

    def evidence_options
      {}
    end
  end
end

Releases::CreateEvidenceService.prepend_mod_with('Releases::CreateEvidenceService')
