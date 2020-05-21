# frozen_string_literal: true

module Ci
  class DagJobEntity < Grape::Entity
    expose :name
    expose :scheduling_type

    expose :needs, if: -> (job, _) { job.scheduling_type_dag? } do |job|
      job.needs.pluck(:name) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
