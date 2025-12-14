# frozen_string_literal: true

module SupplyChain
  ATTEST_BUILD_CI_VARIABLE = "ATTEST_BUILD_ARTIFACTS"
  ATTEST_BUILD_STAGE_NAME = "build"

  class << self
    def publish_provenance_for_build?(build)
      Feature.enabled?(:slsa_provenance_statement, build.project) &&
        build.project.public? &&
        build.stage_name == ATTEST_BUILD_STAGE_NAME &&
        build.yaml_variables.any? { |variable| variable[:key] == ATTEST_BUILD_CI_VARIABLE } &&
        build.artifacts?
    end
  end
end
