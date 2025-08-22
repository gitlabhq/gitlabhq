# frozen_string_literal: true

module Gitlab
  module Ci
    module JobDefinitions
      class FindOrCreate
        BATCH_SIZE = 50

        def initialize(project, partition_id, checksum_to_config)
          @project = project
          @partition_id = partition_id
          @checksum_to_config = checksum_to_config
        end

        # This method assumes that the parameters are valid and can be inserted to the DB safely.
        def execute
          return ::Ci::JobDefinition.none if checksum_to_config.empty?

          checksums = checksum_to_config.keys

          existing = fetch_records_by(checksums)
          missing_checksums = checksums - existing.map(&:checksum)

          return existing if missing_checksums.empty?

          missing_checksums.each_slice(BATCH_SIZE) do |batch|
            insert_missing(batch)
          end

          existing + fetch_records_by(missing_checksums)
        end

        private

        attr_reader :project, :partition_id, :checksum_to_config

        def fetch_records_by(checksums)
          ::Ci::JobDefinition
            .select(:id, :checksum)
            .in_partition(partition_id)
            .for_project(project.id)
            .for_checksum(checksums)
            .to_a # Explicitly convert to array for further processing
        end

        def insert_missing(checksums)
          attributes = build_attributes(checksums)

          ::Ci::JobDefinition.insert_all(
            attributes,
            unique_by: [:project_id, :partition_id, :checksum],
            returning: false # We want to use fetch_records_by again to fetch the records in case there are some
            # lags between read-replicas.
          )
        end

        def build_attributes(checksums)
          current_time = Time.current

          checksums.map do |checksum|
            {
              project_id: project.id,
              partition_id: partition_id,
              checksum: checksum,
              config: checksum_to_config[checksum],
              interruptible: interruptible(checksum),
              created_at: current_time,
              updated_at: current_time
            }
          end
        end

        def interruptible(checksum)
          checksum_to_config[checksum].fetch(:interruptible) do
            ::Ci::JobDefinition.column_defaults['interruptible']
          end
        end
      end
    end
  end
end
