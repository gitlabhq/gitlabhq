# frozen_string_literal: true

module Types
  class UserCalloutType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
    graphql_name 'UserCallout'

    field :dismissed_at, Types::TimeType, null: true,
      description: 'Date when the callout was dismissed.'
    field :feature_name, UserCalloutFeatureNameEnum, null: true,
      description: 'Name of the feature that the callout is for.'
  end
end
