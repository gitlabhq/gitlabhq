# frozen_string_literal: true

module Mutations
  module Ci
    module PipelineSchedule
      class Base < BaseMutation
        PipelineScheduleID = ::Types::GlobalIDType[::Ci::PipelineSchedule]

        argument :id, PipelineScheduleID,
          required: true,
          description: 'ID of the pipeline schedule to mutate.'

        private

        def find_object(id:)
          GlobalID::Locator.locate(id)
        end
      end
    end
  end
end
