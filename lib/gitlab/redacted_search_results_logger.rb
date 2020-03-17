# frozen_string_literal: true

module Gitlab
  class RedactedSearchResultsLogger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'redacted_search_results'
    end
  end
end
