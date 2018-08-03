# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    field :errors, [GraphQL::STRING_TYPE],
          null: false,
          description: "Reasons why the mutation failed."

    def current_user
      context[:current_user]
    end
  end
end
