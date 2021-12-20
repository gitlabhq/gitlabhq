# frozen_string_literal: true

module Gitlab
  # This class has the same interface as SearchResults except
  # it is empty and does not do any work.
  #
  # We use this when responding to abusive search requests.
  class EmptySearchResults
    def initialize(*)
    end

    def objects(*)
      Kaminari.paginate_array([])
    end

    def formatted_count(*)
      '0'
    end

    def highlight_map(*)
      {}
    end

    def aggregations(*)
      []
    end
  end
end
