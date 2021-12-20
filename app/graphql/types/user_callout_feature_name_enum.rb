# frozen_string_literal: true

module Types
  class UserCalloutFeatureNameEnum < BaseEnum
    graphql_name 'UserCalloutFeatureNameEnum'
    description 'Name of the feature that the callout is for.'

    ::Users::Callout.feature_names.keys.each do |feature_name|
      value feature_name.upcase, value: feature_name, description: "Callout feature name for #{feature_name}."
    end
  end
end
