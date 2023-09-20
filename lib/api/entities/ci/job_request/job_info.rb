# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class JobInfo < Grape::Entity
          expose :id, :name, :stage
          expose :project_id, :project_name
          expose :time_in_queue_seconds
          expose :project_jobs_running_on_instance_runners_count
        end
      end
    end
  end
end
