# frozen_string_literal: true

module Types
  module Users
    class GroupCalloutFeatureNameEnum < BaseEnum
      graphql_name 'UserGroupCalloutFeatureName'
      description 'Name of the feature that the callout is for.'

      ::Users::GroupCallout.feature_names.each_key do |feature_name|
        value feature_name.upcase, value: feature_name, description: "Callout feature name for #{feature_name}."
      end
    end
  end
end
