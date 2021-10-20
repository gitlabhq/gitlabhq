# frozen_string_literal: true

module SearchArguments
  extend ActiveSupport::Concern

  included do
    argument :search, GraphQL::Types::String,
             required: false,
             description: 'Search query for title or description.'
  end

  def validate_anonymous_search_access!
    return if current_user.present? || Feature.disabled?(:disable_anonymous_search, type: :ops)

    raise ::Gitlab::Graphql::Errors::ArgumentError,
      "User must be authenticated to include the `search` argument."
  end
end
