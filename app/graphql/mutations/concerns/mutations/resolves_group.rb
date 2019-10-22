# frozen_string_literal: true

module Mutations
  module ResolvesGroup
    extend ActiveSupport::Concern

    def resolve_group(full_path:)
      resolver.resolve(full_path: full_path)
    end

    def resolver
      Resolvers::GroupResolver.new(object: nil, context: context)
    end
  end
end
