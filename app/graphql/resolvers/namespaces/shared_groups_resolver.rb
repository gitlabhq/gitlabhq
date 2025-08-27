# frozen_string_literal: true

module Resolvers
  module Namespaces
    class SharedGroupsResolver < BaseResolver
      include ResolvesGroups

      type Types::GroupType, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search for a specific group.'

      argument :sort, Types::Namespaces::GroupSortEnum,
        required: false,
        description: 'Order by name, path, id or similarity if searching.',
        default_value: :name_asc

      alias_method :parent, :object

      private

      def resolve_groups(args)
        return Group.none unless parent.present?

        ::Namespaces::Groups::SharedGroupsFinder.new(
          parent,
          context[:current_user],
          args.merge({ allow_similarity_sort: true })
        ).execute
      end
    end
  end
end
