# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineSchedule < Grape::Entity
        expose :id
        expose :description, :ref, :cron, :cron_timezone, :next_run_at, :active
        expose :created_at, :updated_at
        expose :owner, using: ::API::Entities::UserBasic
      end
    end
  end
end
