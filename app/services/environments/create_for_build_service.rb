# frozen_string_literal: true

module Environments
  # This class creates an environment record for a build (a pipeline job).
  class CreateForBuildService
    def execute(build)
      return unless build.instance_of?(::Ci::Build) && build.has_environment_keyword?

      environment = to_resource(build)

      if environment.persisted?
        build.persisted_environment = environment
        build.assign_attributes(metadata_attributes: { expanded_environment_name: environment.name })
      else
        build.assign_attributes(status: :failed, failure_reason: :environment_creation_failure)
      end

      environment
    end

    private

    # rubocop: disable Performance/ActiveRecordSubtransactionMethods
    def to_resource(build)
      build.project.environments.safe_find_or_create_by(name: build.expanded_environment_name) do |environment|
        # Initialize the attributes at creation
        environment.auto_stop_in = expanded_auto_stop_in(build)
        environment.tier = build.environment_tier_from_options
        environment.merge_request = build.pipeline.merge_request
      end
    end
    # rubocop: enable Performance/ActiveRecordSubtransactionMethods

    def expanded_auto_stop_in(build)
      return unless build.environment_auto_stop_in

      ExpandVariables.expand(build.environment_auto_stop_in, -> { build.simple_variables.sort_and_expand_all })
    end
  end
end
