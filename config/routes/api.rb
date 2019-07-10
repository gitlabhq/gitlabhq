post '/api/graphql', to: 'graphql#execute'
mount GraphiQL::Rails::Engine, at: '/-/graphql-explorer', graphql_path: '/api/graphql'

::API::API.logger Rails.logger # rubocop:disable Gitlab/RailsLogger
mount ::API::API => '/'
