# frozen_string_literal: true

module Resolvers
  class PaginatedTreeResolver < BaseResolver
    type Types::Tree::TreeType.connection_type, null: true
    extension Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

    calls_gitaly!

    argument :path, GraphQL::Types::String,
              required: false,
              default_value: '', # root of the repository
              description: 'Path to get the tree for. Default value is the root of the repository.'
    argument :recursive, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: 'Used to get a recursive tree. Default is false.'
    argument :ref, GraphQL::Types::String,
              required: false,
              description: 'Commit ref to get the tree for. Default value is HEAD.'

    alias_method :repository, :object

    def resolve(**args)
      return if repository.empty?

      cursor = args.delete(:after)
      args[:ref] ||= :head

      pagination_params = {
        limit: @field.max_page_size || 100,
        page_token: cursor
      }

      tree = repository.tree(
        args[:ref], args[:path], recursive: args[:recursive],
                                 skip_flat_paths: false,
                                 pagination_params: pagination_params
      )

      next_cursor = tree.cursor&.next_cursor
      Gitlab::Graphql::ExternallyPaginatedArray.new(cursor, next_cursor, *tree)
    rescue Gitlab::Git::CommandError => e
      raise Gitlab::Graphql::Errors::BaseError.new(
        e,
        extensions: { code: e.code, gitaly_code: e.status, service: e.service }
      )
    end

    def self.field_options
      super.merge(connection: false) # we manage the pagination manually, so opt out of the connection field extension
    end
  end
end
