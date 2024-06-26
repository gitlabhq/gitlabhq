# frozen_string_literal: true

module Ci
  class UpdateBuildNamesService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      scope = pipeline.builds.latest
      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)

      iterator.each_batch(of: 100) do |records|
        upsert_records(records)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord -- plucking attributes is more efficient than loading the records
    # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- plucking on batch
    def upsert_records(batch)
      keys = %i[build_id partition_id name project_id]

      builds_upsert_data =
        batch
          .pluck(:id, :partition_id, :name, :project_id)
          .map { |values| Hash[keys.zip(values)] }

      return unless builds_upsert_data.any?

      Ci::BuildName.upsert_all(builds_upsert_data, unique_by: [:build_id, :partition_id])
    end
    # rubocop: enable CodeReuse/ActiveRecord
    # rubocop: enable Database/AvoidUsingPluckWithoutLimit
  end
end
