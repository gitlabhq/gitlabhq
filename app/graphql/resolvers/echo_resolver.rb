# frozen_string_literal: true

module Resolvers
  class EchoResolver < BaseResolver
    type ::GraphQL::STRING_TYPE, null: false
    description 'Testing endpoint to validate the API with'

    argument :text,
             type: GraphQL::STRING_TYPE,
             required: true,
             description: 'Text to echo back.'

    def resolve(text:)
      username = current_user&.username

      "#{username.inspect} says: #{text}"
    end
  end
end
