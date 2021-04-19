# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class ConnectionFilterExtension < GraphQL::Schema::FieldExtension
        class Redactor
          include ::Gitlab::Graphql::Laziness

          def initialize(type, context)
            @type = type
            @context = context
          end

          def redact(nodes)
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

          def remove_unauthorized(nodes)
            nodes
              .map! { |lazy| force(lazy) }
              .keep_if { |forced| @type.authorized?(forced, @context) }
          end
        end

        def after_resolve(value:, context:, **rest)
          return value if value.is_a?(GraphQL::Execution::Execute::Skip)

          if @field.connection?
            redact_connection(value, context)
          elsif @field.type.list?
            redact_list(value.to_a, context) unless value.nil?
          end

          value
        end

        def redact_connection(conn, context)
          redactor = Redactor.new(@field.type.unwrap.node_type, context)
          return unless redactor.active?

          conn.redactor = redactor if conn.respond_to?(:redactor=)
        end

        def redact_list(list, context)
          redactor = Redactor.new(@field.type.unwrap, context)
          redactor.redact(list) if redactor.active?
        end
      end
    end
  end
end
