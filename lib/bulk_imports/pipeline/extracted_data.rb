# frozen_string_literal: true

module BulkImports
  module Pipeline
    class ExtractedData
      attr_reader :data

      def initialize(data: nil, page_info: {})
        @data = Array.wrap(data)
        @page_info = page_info
      end

      def has_next_page?
        @page_info['has_next_page']
      end

      def next_page
        @page_info['end_cursor']
      end

      def each(&block)
        data.each(&block)
      end
    end
  end
end
