# frozen_string_literal: true

module Ci
  class DisableUserPipelineSchedulesService
    def execute(user)
      Ci::PipelineSchedule.active.owned_by(user).each_batch do |relation|
        relation.update_all(active: false)
      end
    end
  end
end
