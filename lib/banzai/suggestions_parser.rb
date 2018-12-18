# frozen_string_literal: true

module Banzai
  module SuggestionsParser
    # Returns the content of each suggestion code block.
    #
    def self.parse(text)
      html = Banzai.render(text, project: nil, no_original_data: true)
      doc = Nokogiri::HTML(html)

      doc.search('pre.suggestion').map { |node| node.text }
    end
  end
end
