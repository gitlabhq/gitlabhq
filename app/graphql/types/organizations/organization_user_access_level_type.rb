# frozen_string_literal: true

module Types
  module Organizations
    # rubocop:disable Graphql/AuthorizeTypes -- -- Already authorized in parent OrganizationUserType.
    class OrganizationUserAccessLevelType < Types::BaseObject
      graphql_name 'OrganizationUserAccess'
      description 'Represents the access level of a relationship between a User and Organization that it is related to'

      field :integer_value, GraphQL::Types::Int,
        description: 'Integer representation of access level.',
        experiment: { milestone: '16.11' },
        method: :to_i

      field :string_value, Types::Organizations::OrganizationUserAccessLevelEnum,
        description: 'String representation of access level.',
        experiment: { milestone: '16.11' },
        method: :to_i
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
