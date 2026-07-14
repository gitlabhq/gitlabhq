# frozen_string_literal: true

module Ci
  class CloneJobService
    def initialize(job, current_user:)
      @job = job
      @current_user = current_user
    end

    def execute(new_job_variables: [], new_job_inputs: {})
      new_attributes = build_base_attributes

      add_job_variables_attributes!(new_attributes, new_job_variables)
      add_job_inputs_attributes!(new_attributes, new_job_inputs)
      add_job_definition_attributes!(new_attributes)
      add_job_source_attributes!(new_attributes)

      new_attributes[:user] = current_user

      job.class.new(new_attributes)
    end

    private

    attr_reader :job, :current_user

    delegate :job_definition_instance, :project, :project_id,
      to: :job

    def clone_accessors
      job.class.clone_accessors
    end

    def build_base_attributes
      clone_accessors.index_with { |attribute| job.method(attribute).call }
    end

    def add_job_variables_attributes!(attributes, new_job_variables)
      return unless clone_accessors.include?(:job_variables_attributes)
      return unless job.action? && new_job_variables.any?

      attributes[:job_variables_attributes] = new_job_variables
    end

    def add_job_inputs_attributes!(attributes, new_job_inputs)
      return unless clone_accessors.include?(:inputs_attributes)
      return if new_job_inputs.empty?

      attributes[:inputs_attributes] = new_job_inputs.map do |name, value|
        { name: name, value: value, project: project }
      end
    end

    # The job_source records the origin of a job (e.g. a security policy), which
    # drives the policy badge. A cloned job stays governed by the same policy, so
    # the source must be carried over rather than falling back to the pipeline source.
    def add_job_source_attributes!(attributes)
      return unless job.job_source

      attributes[:job_source_attributes] = {
        source: job.job_source.source,
        project_id: project_id
      }
    end

    def add_job_definition_attributes!(attributes)
      attributes[:job_definition_instance_attributes] = {
        project_id: project_id,
        job_definition_id: job_definition_instance.job_definition_id,
        partition_id: job_definition_instance.partition_id
      }
    end
  end
end
