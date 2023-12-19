# frozen_string_literal: true

module Types
  class ProjectFeatureAccessLevelEnum < BaseEnum
    graphql_name 'ProjectFeatureAccessLevel'
    description 'Access level of a project feature'

    value 'DISABLED', value: ProjectFeature::DISABLED, description: 'Not enabled for anyone.'
    value 'PRIVATE', value: ProjectFeature::PRIVATE, description: 'Enabled only for team members.'
    value 'ENABLED', value: ProjectFeature::ENABLED, description: 'Enabled for everyone able to access the project.'
  end
end
