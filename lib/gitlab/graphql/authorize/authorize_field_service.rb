# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class AuthorizeFieldService
        def initialize(field)
          @field = field
          @old_resolve_proc = @field.resolve_proc
        end

        def authorizations?
          authorizations.present?
        end

        def authorized_resolve
          proc do |obj, args, ctx|
            resolved_obj = @old_resolve_proc.call(obj, args, ctx)
            checker = build_checker(ctx[:current_user])

            if resolved_obj.respond_to?(:then)
              resolved_obj.then(&checker)
            else
              checker.call(resolved_obj)
            end
          end
        end

        private

        def authorizations
          @authorizations ||= (type_authorizations + field_authorizations).uniq
        end

        # Returns any authorize metadata from the return type of @field
        def type_authorizations
          type = @field.type

          # When the return type of @field is a collection, find the singular type
          if type.get_field('edges')
            type = node_type_for_relay_connection(type)
          elsif type.list?
            type = node_type_for_basic_connection(type)
          end

          Array.wrap(type.metadata[:authorize])
        end

        # Returns any authorize metadata from @field
        def field_authorizations
          Array.wrap(@field.metadata[:authorize])
        end

        def build_checker(current_user)
          lambda do |value|
            # Load the elements if they were not loaded by BatchLoader yet
            value = value.sync if value.respond_to?(:sync)

            check = lambda do |object|
              authorizations.all? do |ability|
                Ability.allowed?(current_user, ability, object)
              end
            end

            case value
            when Array, ActiveRecord::Relation
              value.select(&check)
            else
              value if check.call(value)
            end
          end
        end

        # Returns the singular type for relay connections.
        # This will be the type class of edges.node
        def node_type_for_relay_connection(type)
          type = type.get_field('edges').type.unwrap.get_field('node')&.type

          if type.nil?
            raise Gitlab::Graphql::Errors::ConnectionDefinitionError,
              'Connection Type must conform to the Relay Cursor Connections Specification'
          end

          type
        end

        # Returns the singular type for basic connections, for example `[Types::ProjectType]`
        def node_type_for_basic_connection(type)
          type.unwrap
        end
      end
    end
  end
end
