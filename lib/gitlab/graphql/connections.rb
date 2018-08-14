module Gitlab
  module Graphql
    module Connections
      def self.use(_schema)
        GraphQL::Relay::BaseConnection.register_connection_implementation(
          ActiveRecord::Relation,
          Gitlab::Graphql::Connections::KeysetConnection
        )
      end
    end
  end
end
