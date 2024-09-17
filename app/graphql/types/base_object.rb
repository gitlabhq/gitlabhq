# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    prepend Gitlab::Graphql::Present
    prepend Gitlab::Graphql::ExposePermissions
    prepend Gitlab::Graphql::MarkdownField

    field_class Types::BaseField
    edge_type_class Types::BaseEdge

    def self.authorize(*args)
      raise 'Cannot redefine authorize' if @authorize_args && args.any?

      @authorize_args = args.freeze if args.any?
      @authorize_args || (superclass.respond_to?(:authorize) ? superclass.authorize : nil)
    end

    def self.accepts(*types)
      @accepts ||= []
      @accepts += types
      @accepts
    end

    # All graphql fields exposing an id, should expose a global id.
    def id
      GitlabSchema.id_from_object(object)
    end

    def self.authorization_scopes
      [:api, :read_api]
    end

    def self.authorization
      @authorization ||= ::Gitlab::Graphql::Authorize::ObjectAuthorization.new(authorize, authorization_scopes)
    end

    def self.authorized?(object, context)
      authorization.ok?(object, context[:current_user],
        scope_validator: context[:scope_validator],
        skip_abilities: context[:skip_type_authorization]
      )
    end

    def current_user
      context[:current_user]
    end

    def self.assignable?(object)
      assignable = accepts

      return true if assignable.blank?

      assignable.any? { |cls| object.is_a?(cls) }
    end
  end
end
