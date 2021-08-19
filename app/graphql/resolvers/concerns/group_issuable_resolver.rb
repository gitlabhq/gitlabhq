# frozen_string_literal: true

module GroupIssuableResolver
  extend ActiveSupport::Concern

  class_methods do
    def include_subgroups(name_of_things)
      argument :include_subgroups, GraphQL::Types::Boolean,
               required: false,
               default_value: false,
               description: "Include #{name_of_things} belonging to subgroups"
    end
  end
end
