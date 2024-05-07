# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Base < BaseMutation
        PipelineID = ::Types::GlobalIDType[::Ci::Pipeline]

        argument :id, PipelineID,
          required: true,
          description: 'ID of the pipeline to mutate.'

        private

        def find_object(id:)
          GlobalID::Locator.locate(id)
        end
      end
    end
  end
end
