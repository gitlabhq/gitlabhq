# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class JobInfo < Grape::Entity
          expose :id, :name, :stage
          expose :project_id, :project_name
        end
      end
    end
  end
end
