module Mutations
  module ResolvesProject
    extend ActiveSupport::Concern

    def resolve_project(full_path:)
      resolver.resolve(full_path: full_path)
    end

    def resolver
      Resolvers::ProjectResolver.new(object: nil, context: context)
    end
  end
end
