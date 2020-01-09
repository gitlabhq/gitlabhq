# frozen_string_literal: true

# TODO: Eliminate this file when https://github.com/rails/rails/pull/38184 is released.
# Cleanup issue: https://gitlab.com/gitlab-org/gitlab/issues/195841
ActionDispatch::Journey::Formatter.prepend(Gitlab::Patch::ActionDispatchJourneyFormatter)

module ActionDispatch
  module Journey
    module Path
      class Pattern
        def requirements_for_missing_keys_check
          @requirements_for_missing_keys_check ||= requirements.each_with_object({}) do |(key, regex), hash|
            hash[key] = /\A#{regex}\Z/
          end
        end
      end
    end
  end
end
