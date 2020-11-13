# frozen_string_literal: true

module Gitlab
  module Graphql
    module Present
      class Instrumentation
        SAFE_CONTEXT_KEYS = %i[current_user].freeze

        def instrument(type, field)
          return field unless field.metadata[:type_class]

          presented_in = field.metadata[:type_class].owner
          return field unless presented_in.respond_to?(:presenter_class)
          return field unless presented_in.presenter_class

          old_resolver = field.resolve_proc

          resolve_with_presenter = -> (presented_type, args, context) do
            # We need to wrap the original presentation type into a type that
            # uses the presenter as an object.
            object = presented_type.object

            if object.is_a?(presented_in.presenter_class)
              next old_resolver.call(presented_type, args, context)
            end

            attrs = safe_context_values(context)
            presenter = presented_in.presenter_class.new(object, **attrs)

            # we have to use the new `authorized_new` method, as `new` is protected
            wrapped = presented_type.class.authorized_new(presenter, context)

            old_resolver.call(wrapped, args, context)
          end

          field.redefine do
            resolve(resolve_with_presenter)
          end
        end

        private

        def safe_context_values(context)
          context.to_h.slice(*SAFE_CONTEXT_KEYS)
        end
      end
    end
  end
end
