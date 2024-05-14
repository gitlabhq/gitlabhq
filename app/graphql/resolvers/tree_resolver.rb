# frozen_string_literal: true

module Resolvers
  class TreeResolver < BaseResolver
    type Types::Tree::TreeType, null: true

    calls_gitaly!

    argument :path, GraphQL::Types::String,
      required: false,
      default_value: '',
      description: 'Path to get the tree for. Default value is the root of the repository.'
    argument :recursive, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Used to get a recursive tree. Default is false.'
    argument :ref, GraphQL::Types::String,
      required: false,
      description: 'Commit ref to get the tree for. Default value is HEAD.'
    argument :ref_type, Types::RefTypeEnum,
      required: false,
      description: 'Type of ref.'

    alias_method :repository, :object

    def resolve(**args)
      return unless repository.exists?

      ref = (args[:ref].presence || :head)

      repository.tree(ref, args[:path], recursive: args[:recursive], ref_type: args[:ref_type])
    end
  end
end
