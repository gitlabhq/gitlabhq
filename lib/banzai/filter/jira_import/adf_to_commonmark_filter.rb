# frozen_string_literal: true

module Banzai
  module Filter
    module JiraImport
      # Uses Kramdown to convert from the Atlassian Document Format (json)
      # into CommonMark
      # @see https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/
      class AdfToCommonmarkFilter < HTML::Pipeline::TextFilter
        def initialize(text, context = nil, result = nil)
          super(text, context, result)
        end

        def call
          Kramdown::Document.new(@text, input: 'AtlassianDocumentFormat', html_tables: true).to_commonmark
        rescue ::Kramdown::Error => e
          # If we get an error, then just return the original text so at
          # least the user knows something went wrong
          "#{e.message}\n\n#{@text}"
        end
      end
    end
  end
end
