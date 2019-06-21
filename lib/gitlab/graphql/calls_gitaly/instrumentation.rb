# frozen_string_literal: true

module Gitlab
  module Graphql
    module CallsGitaly
      class Instrumentation
        # Check if any `calls_gitaly: true` declarations need to be added
        def instrument(_type, field)
          type_object = field.metadata[:type_class]
          return field unless type_object && type_object.respond_to?(:calls_gitaly_check)

          old_resolver_proc = field.resolve_proc
          wrapped_proc = gitaly_wrapped_resolve(old_resolver_proc, type_object)
          field.redefine { resolve(wrapped_proc) }
        end

        def gitaly_wrapped_resolve(old_resolver_proc, type_object)
          proc do |parent_typed_object, args, ctx|
            previous_gitaly_call_count = Gitlab::GitalyClient.get_request_count

            old_resolver_proc.call(parent_typed_object, args, ctx)

            current_gitaly_call_count = Gitlab::GitalyClient.get_request_count
            type_object.calls_gitaly_check(current_gitaly_call_count - previous_gitaly_call_count)
          end
        end
      end
    end
  end
end
