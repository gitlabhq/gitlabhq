# frozen_string_literal: true

module Mutations
  module Ci
    class Base < BaseMutation
      argument :id, ::Types::GlobalIDType[::Ci::Pipeline],
                required: true,
                description: 'The id of the pipeline to mutate'

      private

      def find_object(id:)
        GlobalID::Locator.locate(id)
      end
    end
  end
end
