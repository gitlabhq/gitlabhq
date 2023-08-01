# frozen_string_literal: true

module Environments
  # This class creates an environment record for a pipeline job.
  class CreateForJobService
    def execute(job)
      return unless job.is_a?(::Ci::Processable) && job.has_environment_keyword?

      environment = to_resource(job)

      if environment.persisted?
        job.persisted_environment = environment
        job.assign_attributes(metadata_attributes: { expanded_environment_name: environment.name })
      else
        job.assign_attributes(status: :failed, failure_reason: :environment_creation_failure)
      end

      environment
    end

    private

    # rubocop: disable Performance/ActiveRecordSubtransactionMethods
    def to_resource(job)
      job.project.environments.safe_find_or_create_by(name: job.expanded_environment_name) do |environment|
        # Initialize the attributes at creation
        environment.auto_stop_in = expanded_auto_stop_in(job)
        environment.tier = job.environment_tier_from_options
        environment.merge_request = job.pipeline.merge_request
      end
    end
    # rubocop: enable Performance/ActiveRecordSubtransactionMethods

    def expanded_auto_stop_in(job)
      return unless job.environment_auto_stop_in

      ExpandVariables.expand(job.environment_auto_stop_in, -> { job.simple_variables.sort_and_expand_all })
    end
  end
end
