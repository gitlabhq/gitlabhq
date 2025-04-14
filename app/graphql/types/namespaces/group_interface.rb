# frozen_string_literal: true

module Types
  module Namespaces
    # This inteface sets [authorize: :read_group] (field-level authorization via
    # GroupBaseField) for all defined fields to ensure implementing types don't
    # expose inherited fields without proper authorization.
    #
    # Implementing types can opt-out from this field-level auth and use
    # type-level auth by re-defining the field without the authorize argument.
    # For example, GroupType uses :read_group type-level auth and redefines all
    # fields in this interface to opt-out while GroupMinimalAccessType uses
    # :read_group_metadata type-level auth to expose a set of defined fields and
    # leaves inherited fields it does not want to expose to use field-level auth
    # using :read_group.
    module GroupInterface
      include BaseInterface

      graphql_name 'GroupInterface'

      # rubocop:disable Layout/LineLength -- otherwise description is creating unnecessary newlines.
      description 'Returns either a "Group" type for users with :read_group permission, or a "GroupMinimalAccess" type for users with only :read_group_metadata permission.'
      # rubocop:enable Layout/LineLength

      field_class GroupBaseField

      field :id, GraphQL::Types::ID, null: true,
        description: 'ID of the group.'
      field :full_name, GraphQL::Types::String, null: true,
        description: 'Full name of the group.'
      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the group.'
      field :web_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Web URL of the group.'
      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Avatar URL of the group.'

      def self.resolve_type(_object, _context)
        ::Types::GroupType
      end
    end
  end
end

Types::Namespaces::GroupInterface.prepend_mod
