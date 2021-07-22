# frozen_string_literal: true

module Resolvers
  class TreeResolver < BaseResolver
    type Types::Tree::TreeType, null: true

    calls_gitaly!

    argument :path, GraphQL::Types::String,
              required: false,
              default_value: '',
              description: 'The path to get the tree for. Default value is the root of the repository.'
    argument :ref, GraphQL::Types::String,
              required: false,
              default_value: :head,
              description: 'The commit ref to get the tree for. Default value is HEAD.'
    argument :recursive, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: 'Used to get a recursive tree. Default is false.'

    alias_method :repository, :object

    def resolve(**args)
      return unless repository.exists?

      repository.tree(args[:ref], args[:path], recursive: args[:recursive])
    end
  end
end
