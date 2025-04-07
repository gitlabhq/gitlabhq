# frozen_string_literal: true

module Types
  module Projects
    # This inteface sets [authorize: :read_project] (field-level authorization via
    # ProjectBaseField) for all defined fields to ensure implementing types don't
    # expose inherited fields without proper authorization.
    #
    # Implementing types can opt-out from this field-level auth and use
    # type-level auth by re-defining the field without the authorize argument.
    # For example, ProjectType uses :read_project type-level auth and redefines all
    # fields in this interface to opt-out while ProjectMinimalAccessType uses
    # :read_project_metadata type-level auth to expose a set of defined fields and
    # leaves inherited fields it does not want to expose to use field-level auth
    # using :read_project.
    module ProjectInterface
      include BaseInterface

      connection_type_class Types::CountableConnectionType

      graphql_name 'ProjectInterface'

      field_class ::Types::Projects::ProjectBaseField

      field :avatar_url, GraphQL::Types::String,
        null: true,
        calls_gitaly: true,
        description: 'Avatar URL of the project.'
      field :description, GraphQL::Types::String,
        null: true,
        description: 'Short description of the project.'
      field :id, GraphQL::Types::ID, null: true,
        description: 'ID of the project.'
      field :name, GraphQL::Types::String,
        null: true,
        description: 'Name of the project without the namespace.'
      field :name_with_namespace, GraphQL::Types::String,
        null: true,
        description: 'Name of the project including the namespace.'
      field :web_url, GraphQL::Types::String,
        null: true,
        description: 'Web URL of the project.'

      def self.resolve_type(_object, _context)
        ::Types::ProjectType
      end

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end

Types::Projects::ProjectInterface.prepend_mod
