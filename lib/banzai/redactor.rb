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
      nodes = documents.flat_map do |document|
        Querying.css(document, 'a.gfm[data-reference-type]')
      end

      redact_nodes(nodes)

      documents
    end

    # Redacts the given nodes
    #
    # nodes - An Array of HTML nodes to redact.
    def redact_nodes(nodes)
      visible = nodes_visible_to_user(nodes)

      nodes.each do |node|
        unless visible.include?(node)
          # The reference should be replaced by the original text,
          # which is not always the same as the rendered text.
          text = node.attr('data-original') || node.text
          node.replace(text)
        end
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
        parser = Banzai::ReferenceParser[type].new(project, user)

        visible.merge(parser.nodes_visible_to_user(user, nodes))
      end

      visible
    end
  end
end
