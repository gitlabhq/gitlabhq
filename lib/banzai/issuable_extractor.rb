# frozen_string_literal: true

module Banzai
  # Extract references to issuables from multiple documents

  # This populates RequestStore cache used in Banzai::ReferenceParser::IssueParser
  # and Banzai::ReferenceParser::MergeRequestParser
  # Populating the cache should happen before processing documents one-by-one
  # so we can avoid N+1 queries problem

  class IssuableExtractor
    attr_reader :context

    ISSUE_REFERENCE_TYPE = '@data-reference-type="issue"'
    MERGE_REQUEST_REFERENCE_TYPE = '@data-reference-type="merge_request"'

    # context - An instance of Banzai::RenderContext.
    def initialize(context)
      @context = context
    end

    # Returns Hash in the form { node => issuable_instance }
    def extract(documents)
      nodes = documents.flat_map do |document|
        document.xpath(query)
      end

      # The project or group for the issuable might be pending for deletion!
      # Filter them out because we don't care about them.
      issuables_for_nodes(nodes).select { |node, issuable| issuable.project || issuable.group }
    end

    private

    def issuables_for_nodes(nodes)
      parsers.each_with_object({}) do |parser, result|
        result.merge!(parser.records_for_nodes(nodes))
      end
    end

    def parsers
      [
        Banzai::ReferenceParser::IssueParser.new(context),
        Banzai::ReferenceParser::MergeRequestParser.new(context)
      ]
    end

    def query
      %Q(
        descendant-or-self::a[contains(concat(" ", @class, " "), " gfm ")]
        [#{reference_types.join(' or ')}]
      )
    end

    def reference_types
      [ISSUE_REFERENCE_TYPE, MERGE_REQUEST_REFERENCE_TYPE]
    end
  end
end

Banzai::IssuableExtractor.prepend_mod_with('Banzai::IssuableExtractor')
