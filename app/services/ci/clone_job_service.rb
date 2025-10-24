# frozen_string_literal: true

module Ci
  class CloneJobService
    def initialize(job, current_user:)
      @job = job
      @current_user = current_user
    end

    def execute(new_job_variables: [])
      new_attributes = build_base_attributes

      add_job_variables_attributes!(new_attributes, new_job_variables)
      add_job_definition_attributes!(new_attributes)

      new_attributes[:user] = current_user

      job.class.new(new_attributes)
    end

    private

    attr_reader :job, :current_user

    delegate :persisted_environment, :expanded_environment_name,
      :job_definition_instance, :project, :project_id,
      :partition_id, :metadata, :pipeline,
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

    def add_job_definition_attributes!(attributes)
      if job_definition_instance
        add_existing_job_definition_attributes!(attributes)
      else
        add_new_job_definition_attributes!(attributes)
      end
    end

    def add_existing_job_definition_attributes!(attributes)
      attributes[:job_definition_instance_attributes] = {
        project_id: project_id,
        job_definition_id: job_definition_instance.job_definition_id,
        partition_id: job_definition_instance.partition_id
      }
    end

    def add_new_job_definition_attributes!(attributes)
      persisted_job_definition = find_or_create_job_definition

      attributes[:job_definition_instance_attributes] = {
        project: project,
        job_definition: persisted_job_definition,
        partition_id: partition_id
      }
    end

    def find_or_create_job_definition
      definition = ::Ci::JobDefinition.fabricate(
        config: build_definition_attributes,
        project_id: project_id,
        partition_id: partition_id
      )

      ::Gitlab::Ci::JobDefinitions::FindOrCreate.new(
        pipeline, definitions: [definition]
      ).execute.first
    end

    def build_definition_attributes
      attrs = {
        options: metadata.config_options,
        yaml_variables: metadata.config_variables,
        id_tokens: metadata.id_tokens,
        secrets: metadata.secrets,
        tag_list: job.tag_list.to_a,
        run_steps: job.try(:execution_config)&.run_steps || []
      }

      attrs[:interruptible] = metadata.interruptible unless metadata.interruptible.nil?

      attrs
    end
  end
end
