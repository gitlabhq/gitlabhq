# frozen_string_literal: true

module Types
  module Ci
    # This inteface sets [authorize: :read_pipeline] (field-level authorization
    # via PipelineBaseField) for all defined fields to ensure implementing types
    # don't expose inherited fields without proper authorization.
    #
    # Implementing types can opt-out from this field-level auth and use
    # type-level auth by re-defining the field without the authorize argument.
    # For example, PipelineType uses :read_pipeline type-level auth and
    # redefines all fields in this interface to opt-out while
    # PipelineMinimalAccessType uses :read_pipeline_metadata type-level auth to
    # expose a set of defined fields and leaves inherited fields it does not
    # want to expose to use field-level auth using :read_pipeline.
    module PipelineInterface
      include BaseInterface

      graphql_name 'PipelineInterface'

      connection_type_class Types::CountableConnectionType

      field_class ::Types::Ci::PipelineBaseField

      field :id, GraphQL::Types::ID, null: true,
        description: 'ID of the pipeline.'
      field :iid, GraphQL::Types::String, null: true,
        description: 'Internal ID of the pipeline.'
      field :path, GraphQL::Types::String, null: true,
        description: "Relative path to the pipeline's page."
      field :project, Types::Projects::ProjectInterface, null: true,
        description: 'Project the pipeline belongs to.'
      field :user,
        type: 'Types::UserType',
        null: true,
        description: 'Pipeline user.'

      def self.resolve_type(_object, _context)
        PipelineType
      end

      def path
        ::Gitlab::Routing.url_helpers.project_pipeline_path(object.project, object)
      end
    end
  end
end

Types::Ci::PipelineInterface.prepend_mod
