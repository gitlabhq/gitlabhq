# frozen_string_literal: true

module Types
  module Organizations
    # rubocop: disable Graphql/AuthorizeTypes -- Already authorized in parent OrganizationUserType.
    class OrganizationUserBadgeType < BaseObject
      graphql_name 'OrganizationUserBadge'
      description 'An organization user badge.'

      authorize_granular_token permissions: :read_badge, boundary: :instance, boundary_type: :instance

      field :text,
        GraphQL::Types::String,
        null: false,
        description: 'Badge text.'

      field :variant,
        GraphQL::Types::String,
        null: false,
        description: 'Badge variant.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
