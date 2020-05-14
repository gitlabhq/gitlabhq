# frozen_string_literal: true

module Ci
  class DagPipelineEntity < Grape::Entity
    expose :ordered_stages_with_preloads, as: :stages, using: Ci::DagStageEntity

    private

    def ordered_stages_with_preloads
      object.ordered_stages.preload(preloaded_relations) # rubocop: disable CodeReuse/ActiveRecord
    end

    def preloaded_relations
      [
        :project,
        { latest_statuses: :needs }
      ]
    end
  end
end
