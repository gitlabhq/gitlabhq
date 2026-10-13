# frozen_string_literal: true

module Types
  module Users
    # rubocop: disable Graphql/AuthorizeTypes -- value object, authorized by the parent field
    class ContributionDayType < BaseObject
      graphql_name 'UserContributionDay'
      description "One day with at least one contribution on a user's contribution calendar."

      authorize_granular_token skip_reason: :parent_authorizes

      field :date, Types::DateType,
        null: false,
        description: "Date of the contributions, in the user's timezone."

      field :count, GraphQL::Types::Int,
        null: false,
        description: 'Number of contributions on the day.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
