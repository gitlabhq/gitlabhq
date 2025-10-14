# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Create
        class JobDefinitionBuilder
          include Gitlab::Utils::StrongMemoize

          def initialize(pipeline, jobs)
            @pipeline = pipeline
            @jobs = jobs.select(&:temp_job_definition)
            @project = pipeline.project
          end

          def run
            find_or_insert_job_definitions.each do |job_definition|
              jobs_by_checksum[job_definition.checksum].each do |job|
                job.build_job_definition_instance(
                  job_definition: job_definition, partition_id: pipeline.partition_id, project: project
                )
              end
            end
          end

          private

          attr_reader :project, :pipeline, :jobs

          def find_or_insert_job_definitions
            Gitlab::Ci::JobDefinitions::FindOrCreate.new(pipeline, definitions: jobs.map(&:temp_job_definition)).execute
          end

          def jobs_by_checksum
            jobs.group_by do |job|
              job.temp_job_definition.checksum
            end
          end
          strong_memoize_attr :jobs_by_checksum
        end
      end
    end
  end
end
