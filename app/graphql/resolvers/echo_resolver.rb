# frozen_string_literal: true

module Resolvers
  class EchoResolver < BaseResolver
    description 'Testing endpoint to validate the API with'

    argument    :text, GraphQL::STRING_TYPE, required: true,
                description: 'Text to echo back'

    def resolve(**args)
      username = context[:current_user]&.username

      "#{username.inspect} says: #{args[:text]}"
    end
  end
end
