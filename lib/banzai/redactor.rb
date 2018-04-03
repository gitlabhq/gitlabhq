module Banzai
  # Class for removing Markdown references a certain user is not allowed to
  # view.
  class Redactor
    attr_reader :context

    # context - An instance of `Banzai::RenderContext`.
    def initialize(context)
      @context = context
    end

    def user
      context.current_user
    end

    # Redacts the references in the given Array of documents.
    #
    # This method modifies the given documents in-place.
    #
    # documents - A list of HTML documents containing references to redact.
    #
    # Returns the documents passed as the first argument.
    def redact(documents)
      redact_cross_project_references(documents) unless can_read_cross_project?

      all_document_nodes = document_nodes(documents)
      redact_document_nodes(all_document_nodes)
    end

    # Redacts the given node documents
    #
    # data - An Array of a Hashes mapping an HTML document to nodes to redact.
    def redact_document_nodes(all_document_nodes)
      all_nodes = all_document_nodes.map { |x| x[:nodes] }.flatten
      visible = nodes_visible_to_user(all_nodes)
      metadata = []

      all_document_nodes.each do |entry|
        nodes_for_document = entry[:nodes]
        doc_data = { document: entry[:document], visible_reference_count: nodes_for_document.count }
        metadata << doc_data

        nodes_for_document.each do |node|
          next if visible.include?(node)

          doc_data[:visible_reference_count] -= 1
          redacted_content = redacted_node_content(node)
          node.replace(redacted_content)
        end
      end

      metadata
    end

    # Return redacted content of given node as either the original link (<a> tag),
    # the original content (text), or the inner HTML of the node.
    #
    def redacted_node_content(node)
      original_content = node.attr('data-original')
      link_reference = node.attr('data-link-reference')

      # Build the raw <a> tag just with a link as href and content if
      # it's originally a link pattern. We shouldn't return a plain text href.
      original_link =
        if link_reference == 'true' && href = original_content
          %(<a href="#{href}">#{href}</a>)
        end

      # The reference should be replaced by the original link's content,
      # which is not always the same as the rendered one.
      original_link || original_content || node.inner_html
    end

    def redact_cross_project_references(documents)
      extractor = Banzai::IssuableExtractor.new(context)
      issuables = extractor.extract(documents)

      issuables.each do |node, issuable|
        next if issuable.project == context.project_for_node(node)

        node['class'] = node['class'].gsub('has-tooltip', '')
        node['title'] = nil
      end
    end

    # Returns the nodes visible to the current user.
    #
    # nodes - The input nodes to check.
    #
    # Returns a new Array containing the visible nodes.
    def nodes_visible_to_user(nodes)
      per_type = Hash.new { |h, k| h[k] = [] }
      visible = Set.new

      nodes.each do |node|
        per_type[node.attr('data-reference-type')] << node
      end

      per_type.each do |type, nodes|
        parser = Banzai::ReferenceParser[type].new(context)

        visible.merge(parser.nodes_visible_to_user(user, nodes))
      end

      visible
    end

    def document_nodes(documents)
      documents.map do |document|
        { document: document, nodes: Querying.css(document, 'a.gfm[data-reference-type]') }
      end
    end

    private

    def can_read_cross_project?
      Ability.allowed?(user, :read_cross_project)
    end
  end
end
