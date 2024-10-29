# frozen_string_literal: true

match '/api/graphql', via: [:get, :post], to: 'graphql#execute'
get '/-/graphql-explorer', to: API::Graphql::GraphqlExplorerController.action(:show)

::API::API.logger Rails.logger
mount ::API::API => '/'
