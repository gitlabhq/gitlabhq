module Banzai
  # Class for removing Markdown references a certain user is not allowed to
  # view.
  class Redactor
    attr_reader :user, :project

    # project - A Project to use for redacting links.
    # user - The currently logged in user (if any).
    def initialize(project, user = nil)
      @project = project
      @user = user
    end

    # Redacts the references in the given Array of documents.
    #
    # This method modifies the given documents in-place.
    #
    # documents - A list of HTML documents containing references to redact.
    #
    # Returns the documents passed as the first argument.
    def redact(documents)
      all_document_nodes = ReferenceQuerying.document_nodes(documents)

      redact_document_nodes(all_document_nodes)
    end

    # Redacts the given node documents
    #
    # data - An Array of a Hashes mapping an HTML document to nodes to redact.
    def redact_document_nodes(all_document_nodes)
      all_nodes = all_document_nodes.map { |x| x.nodes }.flatten
      visible = nodes_visible_to_user(all_nodes)
      metadata = []

      all_document_nodes.each do |entry|
        nodes_for_document = entry.nodes
        doc_data = { document: entry.document, visible_reference_count: nodes_for_document.count }
        metadata << doc_data

        nodes_for_document.each do |node|
          next if visible.include?(node)

          doc_data[:visible_reference_count] -= 1
          # The reference should be replaced by the original text,
          # which is not always the same as the rendered text.
          text = node.attr('data-original') || node.text
          node.replace(text)
        end
      end

      metadata
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
        parser = Banzai::ReferenceParser[type].new(project, user)

        visible.merge(parser.nodes_visible_to_user(user, nodes))
      end

      visible
    end
  end
end
