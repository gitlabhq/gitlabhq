module Gitlab
  module Graphql
    class Present
      PRESENT_USING = -> (type, presenter_class, *args) do
        type.metadata[:presenter_class] = presenter_class
      end

      INSTRUMENT_PROC = -> (schema) do
        schema.instrument(:field, new)
      end

      def self.register!
        GraphQL::Schema.accepts_definitions(enable_presenting: INSTRUMENT_PROC)
        GraphQL::ObjectType.accepts_definitions(present_using: PRESENT_USING)
      end

      def instrument(type, field)
        return field unless type.metadata[:presenter_class]

        old_resolver = field.resolve_proc

        resolve_with_presenter = -> (obj, args, context) do
          presenter = type.metadata[:presenter_class].new(obj, **context.to_h)

          old_resolver.call(presenter, args, context)
        end

        field.redefine do
          resolve(resolve_with_presenter)
        end
      end
    end
  end
end
