# frozen_string_literal: true

module Types
  module Users
    class GroupCalloutType < BaseObject
      graphql_name 'UserGroupCallout'

      authorize :read_user

      field :dismissed_at, Types::TimeType, null: false, description: 'Date when the callout was dismissed.'
      field :feature_name,
        Users::GroupCalloutFeatureNameEnum,
        null: false,
        description: 'Name of the feature that the callout is for.'
      field :group_id, ::Types::GlobalIDType[::Group], null: false, description: 'Group id that the callout applies.'
    end
  end
end
