# frozen_string_literal: true

module Types
  module MergeRequests
    class ConflictSectionType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- authorized by the parent merge request
      graphql_name 'MergeRequestConflictSection'
      description 'Conflict in a file, with the lines each side of the conflict keeps.'

      authorize_granular_token skip_reason: :parent_authorizes

      # Not `id`: a section ID is only unique within one file, so it must not become a global ID
      field :section_id, GraphQL::Types::String, null: false, hash_key: :id,
        description: 'ID of the section. Pass it back unchanged to choose a side of the conflict.'

      field :our_lines, [GraphQL::Types::String], null: false,
        description: 'Lines of the source branch, kept when the conflict is resolved with the source branch.'

      field :their_lines, [GraphQL::Types::String], null: false,
        description: 'Lines of the target branch, kept when the conflict is resolved with the target branch.'

      def our_lines
        lines_of_type('new')
      end

      def their_lines
        lines_of_type('old')
      end

      private

      def lines_of_type(type)
        object[:lines].select { |line| line.type == type }.map(&:text)
      end
    end
  end
end
