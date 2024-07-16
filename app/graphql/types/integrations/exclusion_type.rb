# frozen_string_literal: true

module Types
  module Integrations
    class ExclusionType < BaseObject
      graphql_name 'IntegrationExclusion'
      description 'An integration to override the level settings of instance specific integrations.'
      authorize :admin_all_resources

      field :group, ::Types::GroupType,
        description: 'Group that has been excluded from the instance specific integration.'
      field :project, ::Types::ProjectType,
        description: 'Project that has been excluded from the instance specific integration.'
    end
  end
end
