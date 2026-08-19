# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUserPreferencesEmojiAutocompleteDisabledMetric < DatabaseMetric
          operation :count

          relation { ::UserPreference.with_user.emoji_autocomplete_disabled.merge(::User.active) }
        end
      end
    end
  end
end
