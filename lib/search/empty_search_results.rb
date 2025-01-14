# frozen_string_literal: true

module Search
  # This class has the same interface as SearchResults except
  # it is empty and does not do any work.
  class EmptySearchResults
    attr_reader :error

    def initialize(error: nil)
      @error = error
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

    def failed?(*)
      error.present?
    end

    def blobs_count
      0
    end

    def file_count
      0
    end
  end
end
