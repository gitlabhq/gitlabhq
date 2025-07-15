# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module RunnerJobExecutionStatusHelper
        # Efficiently determines job execution status for multiple runners using BatchLoader
        # to avoid N+1 queries. Returns :active if runner has executing builds, :idle otherwise.
        def lazy_job_execution_status(object:, key:)
          BatchLoader.for(object.id).batch(key: key) do |object_ids, loader|
            statuses = object.class.id_in(object_ids).with_executing_builds.index_by(&:id)

            object_ids.each do |id|
              loader.call(id, statuses[id] ? :active : :idle)
            end
          end
        end
      end
    end
  end
end
