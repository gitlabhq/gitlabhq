# frozen_string_literal: true

module Ci
  class UpdateBuildNamesService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    # rubocop: disable CodeReuse/ActiveRecord -- plucking attributes is more efficient than loading the records
    # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- plucking on batch
    def execute
      keys = %i[build_id partition_id name project_id]
      pipeline.latest_builds.each_batch(of: 50) do |batch|
        builds_upsert_data =
          batch
            .pluck(:id, :partition_id, :name, :project_id)
            .map { |values| Hash[keys.zip(values)] }

        Ci::BuildName.upsert_all(builds_upsert_data, unique_by: [:build_id, :partition_id])
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
    # rubocop: enable Database/AvoidUsingPluckWithoutLimit
  end
end
