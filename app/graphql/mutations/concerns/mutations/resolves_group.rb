# frozen_string_literal: true

module Mutations
  module ResolvesGroup
    extend ActiveSupport::Concern

    def resolve_group(full_path:)
      group_resolver.resolve(full_path: full_path)
    end

    def group_resolver
      Resolvers::GroupResolver.new(object: nil, context: context, field: nil)
    end
  end
end
