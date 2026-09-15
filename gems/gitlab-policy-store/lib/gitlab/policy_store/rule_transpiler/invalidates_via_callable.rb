# frozen_string_literal: true

module Gitlab
  module PolicyStore
    class RuleTranspiler
      # Forwards to the `invalid:`/`reported_value:` callables the including class receives via
      # its own constructor and stores as `@invalid`/`@reported_value`; `RuleTranspiler` is the
      # only place their message format and truncation logic are implemented.
      module InvalidatesViaCallable
        private

        def invalid!(message)
          invalid_callable.call(message)
        end

        def reported_value(raw_value)
          reported_value_callable.call(raw_value)
        end

        def invalid_callable
          @invalid
        end

        def reported_value_callable
          @reported_value
        end
      end
    end
  end
end
