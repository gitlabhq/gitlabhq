# frozen_string_literal: true

module SupplyChain
  ATTEST_ARTIFACTS_VARIABLE = "ATTEST_BUILD_ARTIFACTS"
  ATTEST_CONTAINERS_VARIABLE = "ATTEST_CONTAINER_IMAGES"
  IMAGE_DIGEST_VARIABLE = "IMAGE_DIGEST"
  ATTEST_BUILD_STAGE_NAME = "build"

  class << self
    def publish_provenance_for_build?(build)
      return false unless build
      return false unless Feature.enabled?(:slsa_provenance_statement, build.project)

      is_public = build.project.public?
      has_correct_stage_name = build.stage_name == ATTEST_BUILD_STAGE_NAME
      requires_artifact_provenance = publish_artifact_provenance?(build)
      requires_container_provenance = publish_container_provenance?(build)

      should_publish_provenance = is_public && has_correct_stage_name && (requires_artifact_provenance ||
                                                                      requires_container_provenance)

      # TODO: Remove once FF is rolled out to avoid excessive logging.
      unless should_publish_provenance
        Gitlab::AppJsonLogger.info(message: "Not publishing attestations for build", build_id: build.id, is_public:
          is_public, has_correct_stage_name: has_correct_stage_name,
          requires_artifact_provenance: requires_artifact_provenance,
          requires_container_provenance: requires_container_provenance)
      end

      should_publish_provenance
    end

    def publish_artifact_provenance?(build)
      yaml_variable_truthy?(build, ATTEST_ARTIFACTS_VARIABLE) && build.artifacts?
    end

    def publish_container_provenance?(build)
      yaml_variable_truthy?(build, ATTEST_CONTAINERS_VARIABLE) && !build.variables[IMAGE_DIGEST_VARIABLE].nil?
    end

    private

    def yaml_variable_truthy?(build, variable)
      return false unless build.yaml_variables

      yaml_variable = build.yaml_variables.find { |v| v[:key] == variable }

      return false unless yaml_variable

      Gitlab::Utils.to_boolean(yaml_variable[:value], default: true)
    end
  end
end
