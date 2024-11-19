# frozen_string_literal: true

module Mutations
  module Timelogs
    class Base < Mutations::BaseMutation
      field :timelog,
        Types::TimelogType,
        null: true,
        description: 'Timelog.'

      private

      def response(result)
        { timelog: result.payload[:timelog], errors: result.errors }
      end
    end
  end
end
