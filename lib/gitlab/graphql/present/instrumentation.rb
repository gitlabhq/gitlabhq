module Gitlab
  module Graphql
    module Present
      class Instrumentation
        def instrument(type, field)
          presented_in = field.metadata[:type_class].owner
          return field unless presented_in.respond_to?(:presenter_class)
          return field unless presented_in.presenter_class

          old_resolver = field.resolve_proc

          resolve_with_presenter = -> (presented_type, args, context) do
            object = presented_type.object
            presenter = presented_in.presenter_class.new(object, **context.to_h)
            old_resolver.call(presenter, args, context)
          end

          field.redefine do
            resolve(resolve_with_presenter)
          end
        end
      end
    end
  end
end
