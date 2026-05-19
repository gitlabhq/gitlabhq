# frozen_string_literal: true

module API
  module Ci
    module Helpers
      module RunnerJobExecutionStatusHelper
        # Efficiently determines job execution status for multiple runners using BatchLoader
        # to avoid N+1 queries. Returns :active if runner has running builds, :idle otherwise.
        def lazy_job_execution_status(object:, key:)
          BatchLoader.for(object.id).batch(key: key) do |object_ids, loader|
            # We ignore `canceling` builds because they're short-lived
            active_ids = object.class.ids_with_running_builds(object_ids).to_set

            object_ids.each do |id|
              loader.call(id, active_ids.include?(id) ? :active : :idle)
            end
          end
        end
      end
    end
  end
end
