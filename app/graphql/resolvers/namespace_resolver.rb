# frozen_string_literal: true

module Resolvers
  class NamespaceResolver < BaseResolver
    prepend FullPathResolver

    type Types::NamespaceType, null: true

    def resolve(full_path:)
      model_by_full_path(Namespace, full_path)
    end
  end
end
