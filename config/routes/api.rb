constraints(::Constraints::FeatureConstrainer.new(:graphql)) do
  post '/api/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/-/graphql-explorer', graphql_path: '/api/graphql'
end

<<<<<<< HEAD
::API::API.logger Rails.logger
mount ::API::API => '/'
=======
API::API.logger Rails.logger
mount API::API => '/'
>>>>>>> upstream/master
