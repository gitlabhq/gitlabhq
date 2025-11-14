# frozen_string_literal: true

unless @organization_scoped_routes
  match '/api/graphql', via: [:get, :post], to: 'graphql#execute'
  match '/api/glql', via: [:get, :post], to: 'glql/base#execute'
  get '/-/graphql-explorer', to: API::Graphql::GraphqlExplorerController.action(:show)

  ::API::API.logger Rails.logger
  mount ::API::API => '/'
end
