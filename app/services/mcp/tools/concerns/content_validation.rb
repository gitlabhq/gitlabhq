# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module ContentValidation
        QUICK_ACTION_PATTERN = %r{^\s*/\w+}

        protected

        def validate_no_quick_actions!(text, field_name: 'text')
          return unless text&.match?(QUICK_ACTION_PATTERN)

          raise ArgumentError, "Quick actions (commands starting with /) are not allowed in #{field_name}"
        end
      end
    end
  end
end
