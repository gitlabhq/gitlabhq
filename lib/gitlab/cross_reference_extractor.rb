module Gitlab
  class CrossReferenceExtractor
    def initialize(project, user)
      @project = project
      @user    = user
    end

    def references_with_object(objects, attr)
      documents          = Banzai::MentionableRenderer.render_objects(objects, attr, project, user)
      all_document_nodes = Banzai::ReferenceQuerying.document_nodes(documents, TYPES)
      populate_reference_parser_cache(all_document_nodes)

      objects.each_with_index do |object, index|
        document_nodes = all_document_nodes[index]

        # Here we're going to limit the references from those only on the commit nodes
        # and that are visible for the commit author.
        # Using the same parser we ensure the entities are already cached.
        refs = TYPES.flat_map { |type| redact_references(type, object, document_nodes) }.compact

        yield object, refs
      end
    end

    private

    attr_reader :project, :user

    TYPES = %i(issue external_issue merge_request commit)

    def redact_references(type, object, document_nodes)
      nodes = document_nodes.nodes_by_type[type] || []

      refs = parsers[type].gather_references(nodes, object_author(object)).to_a
      # From mentionable#referenced_mentionables
      refs.reject! { |ref| ref == object.local_reference }
      refs
    end

    def object_author(object)
      object.author || user
    end

    # This method find reference using all the nodes to populate internal reference cache on ther Parser classes
    # See Banzai::Reference::BaseParser#collection_objects_for_ids
    def populate_reference_parser_cache(all_document_nodes)
      TYPES.each do |type|
        nodes = all_document_nodes.flat_map { |document_nodes| document_nodes.nodes_by_type[type] }
        parsers[type].referenced_by(nodes).to_a
      end
    end

    # We cache parsers because we pretend use their internal caching inverting their execution
    # order.
    # 1. we get the references on the whole set of nodes
    # 2. we get visible_nodes for the user generated nodes
    def parsers
      @parsers ||= Hash.new do |hash, type|
        hash[type] = Banzai::ReferenceParser[type].new(project, user)
      end
    end
  end
end
