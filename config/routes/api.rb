post '/api/graphql', to: 'graphql#execute'
mount GraphiQL::Rails::Engine, at: '/-/graphql-explorer', graphql_path: Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/api/graphql')

::API::API.logger Rails.logger # rubocop:disable Gitlab/RailsLogger
mount ::API::API => '/'
