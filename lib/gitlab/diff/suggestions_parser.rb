# frozen_string_literal: true

module Gitlab
  module Diff
    class SuggestionsParser
      # Matches for instance "-1", "+1" or "-1+2".
      SUGGESTION_CONTEXT = /^(\-(?<above>\d+))?(\+(?<below>\d+))?$/.freeze
    end
  end
end
