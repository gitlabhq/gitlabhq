# frozen_string_literal: true

module Releases
  class CreateEvidenceService
    def initialize(release)
      @release = release
    end

    def execute
      evidence = release.evidences.build

      summary = Evidences::EvidenceSerializer.new.represent(evidence) # rubocop: disable CodeReuse/Serializer
      evidence.summary = summary
      # TODO: fix the sha generating https://gitlab.com/gitlab-org/gitlab/-/issues/209000
      evidence.summary_sha = Gitlab::CryptoHelper.sha256(summary)

      evidence.save!
    end

    private

    attr_reader :release
  end
end
