# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class UserStatusType < BaseObject
    graphql_name 'UserStatus'

    markdown_field :message_html, null: true,
      description: 'HTML of the user status message'
    field :availability, Types::AvailabilityEnum, null: false,
      description: 'User availability status.'
    field :emoji, GraphQL::Types::String, null: true,
      description: 'String representation of emoji.'
    field :message, GraphQL::Types::String, null: true,
      description: 'User status message.'
  end
end
