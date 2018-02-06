module Banzai
  # Extract references to issuables from multiple documents

  # This populates RequestStore cache used in Banzai::ReferenceParser::IssueParser
  # and Banzai::ReferenceParser::MergeRequestParser
  # Populating the cache should happen before processing documents one-by-one
  # so we can avoid N+1 queries problem

  class IssuableExtractor
    QUERY = %q(
      descendant-or-self::a[contains(concat(" ", @class, " "), " gfm ")]
      [@data-reference-type="issue" or @data-reference-type="merge_request"]
    ).freeze

    attr_reader :project, :user

    def initialize(project, user)
      @project = project
      @user = user
    end

    # Returns Hash in the form { node => issuable_instance }
    def extract(documents)
      nodes = documents.flat_map do |document|
        document.xpath(QUERY)
      end

      issue_parser = Banzai::ReferenceParser::IssueParser.new(project, user)
      merge_request_parser = Banzai::ReferenceParser::MergeRequestParser.new(project, user)

      issuables_for_nodes = issue_parser.records_for_nodes(nodes).merge(
        merge_request_parser.records_for_nodes(nodes)
      )

      # The project for the issue/MR might be pending for deletion!
      # Filter them out because we don't care about them.
      issuables_for_nodes.select { |node, issuable| issuable.project }
    end
  end
end
