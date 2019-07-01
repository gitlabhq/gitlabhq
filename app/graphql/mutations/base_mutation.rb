# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    prepend Gitlab::Graphql::Authorize::AuthorizeResource
    prepend Gitlab::Graphql::CopyFieldDescription

    field :errors, [GraphQL::STRING_TYPE],
          null: false,
          description: "Reasons why the mutation failed."

    def current_user
      context[:current_user]
    end

    # Returns Array of errors on an ActiveRecord object
    def errors_on_object(record)
      record.errors.full_messages
    end
  end
end
