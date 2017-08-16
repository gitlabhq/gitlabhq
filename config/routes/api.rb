post '/api/graphql', to: 'graphql#execute'

API::API.logger Rails.logger
mount API::API => '/'
