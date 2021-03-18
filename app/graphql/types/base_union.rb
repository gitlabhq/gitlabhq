# frozen_string_literal: true

module Types
  class BaseUnion < GraphQL::Schema::Union
    def self.authorized?(object, context)
      resolve_type(object, context).authorized?(object, context)
    end
  end
end
