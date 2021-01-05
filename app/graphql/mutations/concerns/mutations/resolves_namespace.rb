# frozen_string_literal: true

module Mutations
  module ResolvesNamespace
    extend ActiveSupport::Concern

    def resolve_namespace(full_path:)
      namespace_resolver.resolve(full_path: full_path)
    end

    def namespace_resolver
      Resolvers::NamespaceResolver.new(object: nil, context: context, field: nil)
    end
  end
end
