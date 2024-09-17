# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class FieldExtension < GraphQL::Schema::FieldExtension
        class Redactor
          include ::Gitlab::Graphql::Laziness

          def initialize(type, context, resolver)
            @type = type
            @context = context
            @resolver = resolver
          end

          def redact(nodes)
            perform_before_authorize_action(nodes)
            remove_unauthorized(nodes)

            nodes
          end

          def active?
            # some scalar types (such as integers) do not respond to :authorized?
            return false unless @type.respond_to?(:authorized?)

            auth = @type.try(:authorization)

            auth.nil? || auth.any?
          end

          private

          def perform_before_authorize_action(nodes)
            before_connection_authorization_block = @resolver&.before_connection_authorization_block
            return unless before_connection_authorization_block.respond_to?(:call)

            before_connection_authorization_block.call(nodes, @context[:current_user])
          end

          def remove_unauthorized(nodes)
            nodes
              .map! { |lazy| force(lazy) }
              .keep_if { |forced| @type.authorized?(forced, @context) }
          end
        end

        def after_resolve(value:, context:, **_rest)
          return value if value.is_a?(GraphQL::Execution::Skip)

          set_skip_type_authorization(context)

          if @field.connection?
            redact_connection(value, context)
          elsif @field.type.list?
            unless value.nil?
              value = value.to_a
              redact_list(value, context)
            end
          end

          value
        end

        def redact_connection(conn, context)
          redactor = Redactor.new(@field.type.unwrap.node_type, context, @field.resolver)
          return unless redactor.active?

          conn.redactor = redactor if conn.respond_to?(:redactor=)
        end

        def redact_list(list, context)
          redactor = Redactor.new(@field.type.unwrap, context, @field.resolver)
          redactor.redact(list) if redactor.active?
        end

        def set_skip_type_authorization(context)
          skip_type_authorization = Array.wrap(
            [@field.skip_type_authorization, context[:skip_type_authorization]]
          ).flatten.compact.uniq

          context.scoped_set!(:skip_type_authorization, skip_type_authorization) if skip_type_authorization.any?
        end
      end
    end
  end
end
