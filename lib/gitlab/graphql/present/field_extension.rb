# frozen_string_literal: true

module Gitlab
  module Graphql
    module Present
      class FieldExtension < ::GraphQL::Schema::FieldExtension
        SAFE_CONTEXT_KEYS = %i[current_user].freeze

        def resolve(object:, arguments:, context:)
          attrs = safe_context_values(context)

          # We need to handle the object being either a Schema::Object or an
          # inner Schema::Object#object. This depends on whether the field
          # has a @resolver_proc or not.
          if object.is_a?(::Types::BaseObject)
            type = field.owner.kind.abstract? ? object.class : field.owner
            object.present(type, attrs)
            yield(object, arguments)
          else
            # This is the legacy code-path, hit if the field has a @resolver_proc
            # TODO: remove this when resolve procs are removed from the
            # graphql-ruby library, and all field instrumentation is removed.
            # See: https://github.com/rmosolgo/graphql-ruby/issues/3385
            presented = field.owner.try(:present, object, attrs) || object
            yield(presented, arguments)
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
