# frozen_string_literal: true

module Resolvers
  module Environments
    class NestedEnvironmentsResolver < EnvironmentsResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::NestedEnvironmentType, null: true

      authorizes_object!
      authorize :read_environment

      def resolve(**args)
        offset_pagination(super(**args).nested)
      end
    end
  end
end
