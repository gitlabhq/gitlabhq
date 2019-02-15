# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    def self.single
      @single ||= Class.new(self) do
        def resolve(**args)
          super.first
        end
      end
    end
  end
end
