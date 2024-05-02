# frozen_string_literal: true

module Resolvers
  class PagesDeploymentsResolver < BaseResolver
    type Types::PagesDeploymentType.connection_type, null: true

    argument :active, GraphQL::Types::Boolean, required: false, description: "Filter by active or inactive state."
    argument :sort, Types::SortEnum, required: false, description: "Sort results."
    argument :versioned, GraphQL::Types::Boolean, required: false, description: "Filter deployments that are
versioned or unversioned."

    def resolve(**args)
      Pages::DeploymentsFinder.new(object, args).execute
    end
  end
end
