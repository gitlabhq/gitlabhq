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

          gitaly_wrapped_resolve = -> (typed_object, args, ctx) do
            previous_gitaly_call_count = Gitlab::GitalyClient.get_request_count
            result = old_resolver_proc.call(typed_object, args, ctx)
            current_gitaly_call_count = Gitlab::GitalyClient.get_request_count
            type_object.calls_gitaly_check(current_gitaly_call_count - previous_gitaly_call_count)
            result
          rescue => e
            ap "#{e.message}"
          end

          field.redefine do
            resolve(gitaly_wrapped_resolve)
          end
        end
      end
    end
  end
end
