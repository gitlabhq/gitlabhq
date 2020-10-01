# frozen_string_literal: true

module Mutations
  module Ci
    class Base < BaseMutation
      PipelineID = ::Types::GlobalIDType[::Ci::Pipeline]

      argument :id, PipelineID,
                required: true,
                description: 'The id of the pipeline to mutate'

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = PipelineID.coerce_isolated_input(id)
        GlobalID::Locator.locate(id)
      end
    end
  end
end
