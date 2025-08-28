# frozen_string_literal: true

module Gitlab
  module Ci
    module JobDefinitions
      class FindOrCreate
        BATCH_SIZE = 50

        def initialize(pipeline, jobs)
          @project_id = pipeline.project_id
          @partition_id = pipeline.partition_id
          @job_definitions = Array.wrap(jobs).map(&:temp_job_definition).uniq(&:checksum)
        end

        def execute
          return [] if job_definitions.empty?

          existing_definitions = fetch_records_for(job_definitions)
          existing_definitions_by_checksum = existing_definitions.group_by(&:checksum)
          missing_definitions = @job_definitions.reject do |d|
            existing_definitions_by_checksum[d.checksum]
          end

          return existing_definitions if missing_definitions.empty?

          insert_missing(missing_definitions)

          existing_definitions + fetch_records_for(missing_definitions)
        end

        private

        attr_reader :project_id, :partition_id, :job_definitions

        def fetch_records_for(definitions)
          checksums = definitions.map(&:checksum)

          ::Ci::JobDefinition
            .select(:id, :partition_id, :project_id, :checksum, :interruptible)
            .in_partition(partition_id)
            .for_project(project_id)
            .for_checksum(checksums)
            .to_a # Explicitly convert to array for further processing
        end

        def insert_missing(definitions)
          ::Ci::JobDefinition.bulk_insert!(
            definitions,
            unique_by: [:project_id, :partition_id, :checksum],
            skip_duplicates: true,
            batch_size: BATCH_SIZE
          )
        end
      end
    end
  end
end
