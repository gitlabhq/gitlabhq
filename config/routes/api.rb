post '/api/graphql', to: 'graphql#execute'
mount GraphiQL::Rails::Engine, at: '/api/graphiql', graphql_path: '/api/graphql'

API::API.logger Rails.logger
mount API::API => '/'
