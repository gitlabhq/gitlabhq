# frozen_string_literal: true

module Resolvers
  class NilResolver < BaseResolver # rubocop:disable Gitlab/BoundedContexts -- Part of base GraphQL feature
    type ::GraphQL::Types::Boolean, null: true
    description 'Returns nil. Used to resolve the value of missing fields with the @gl_introduced directive.'

    def resolve
      nil
    end
  end
end
