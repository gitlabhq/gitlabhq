module Banzai
  module ReferenceParser
    # Base class for reference parsing classes.
    #
    # Each parser should also specify its reference type by calling
    # `self.reference_type = ...` in the body of the class. The value of this
    # method should be a symbol such as `:issue` or `:merge_request`. For
    # example:
    #
    #     class IssueParser < BaseParser
    #       self.reference_type = :issue
    #     end
    #
    # The reference type is used to determine what nodes to pass to the
    # `referenced_by` method.
    #
    # Parser classes should either implement the instance method
    # `references_relation` or overwrite `referenced_by`. The
    # `references_relation` method is supposed to return an
    # ActiveRecord::Relation used as a base relation for retrieving the objects
    # referenced in a set of HTML nodes.
    #
    # Each class can implement two additional methods:
    #
    # * `nodes_user_can_reference`: returns an Array of nodes the given user can
    #   refer to.
    # * `nodes_visible_to_user`: returns an Array of nodes that are visible to
    #   the given user.
    #
    # You only need to overwrite these methods if you want to tweak who can see
    # which references. For example, the IssueParser class defines its own
    # `nodes_visible_to_user` method so it can ensure users can only see issues
    # they have access to.
    class BaseParser
      class << self
        attr_accessor :reference_type, :reference_options
      end

      # Returns the attribute name containing the value for every object to be
      # parsed by the current parser.
      #
      # For example, for a parser class that returns "Animal" objects this
      # attribute would be "data-animal".
      def self.data_attribute
        @data_attribute ||= "data-#{reference_type.to_s.dasherize}"
      end

      # context - An instance of `Banzai::RenderContext`.
      def initialize(context)
        @context = context
      end

      def project_for_node(node)
        context.project_for_node(node)
      end

      # Returns all the nodes containing references that the user can refer to.
      def nodes_user_can_reference(user, nodes)
        nodes
      end

      # Returns all the nodes that are visible to the given user.
      def nodes_visible_to_user(user, nodes)
        projects = lazy { projects_for_nodes(nodes) }
        project_attr = 'data-project'

        nodes.select do |node|
          if node.has_attribute?(project_attr)
            can_read_reference?(user, projects[node], node)
          else
            true
          end
        end
      end

      # Returns an Array of objects referenced by any of the given HTML nodes.
      def referenced_by(nodes)
        ids = unique_attribute_values(nodes, self.class.data_attribute)

        if ids.empty?
          references_relation.none
        else
          references_relation.where(id: ids)
        end
      end

      # Returns the ActiveRecord::Relation to use for querying references in the
      # DB.
      def references_relation
        raise NotImplementedError,
          "#{self.class} does not implement #{__method__}"
      end

      # Returns a Hash containing attribute values per project ID.
      #
      # The returned Hash uses the following format:
      #
      #     { project id => [value1, value2, ...] }
      #
      # nodes - An Array of HTML nodes to process.
      # attribute - The name of the attribute (as a String) for which to gather
      #             values.
      #
      # Returns a Hash.
      def gather_attributes_per_project(nodes, attribute)
        per_project = Hash.new { |hash, key| hash[key] = Set.new }

        nodes.each do |node|
          project_id = node.attr('data-project').to_i
          id = node.attr(attribute)

          per_project[project_id] << id if id
        end

        per_project
      end

      # Returns a Hash containing objects for an attribute grouped per the
      # nodes that reference them.
      #
      # The returned Hash uses the following format:
      #
      #     { node => row }
      #
      # nodes - An Array of HTML nodes to process.
      #
      # collection - The model or ActiveRecord relation to use for retrieving
      #              rows from the database.
      #
      # attribute - The name of the attribute containing the primary key values
      #             for every row.
      #
      # Returns a Hash.
      def grouped_objects_for_nodes(nodes, collection, attribute)
        return {} if nodes.empty?

        ids = unique_attribute_values(nodes, attribute)
        collection_objects = collection_objects_for_ids(collection, ids)
        objects_by_id = collection_objects.index_by(&:id)

        nodes.each_with_object({}) do |node, hash|
          if node.has_attribute?(attribute)
            obj = objects_by_id[node.attr(attribute).to_i]
            hash[node] = obj if obj
          end
        end
      end

      # Returns an Array containing all unique values of an attribute of the
      # given nodes.
      def unique_attribute_values(nodes, attribute)
        values = Set.new

        nodes.each do |node|
          if node.has_attribute?(attribute)
            values << node.attr(attribute)
          end
        end

        values.to_a
      end

      # Queries the collection for the objects with the given IDs.
      #
      # If the RequestStore module is enabled this method will only query any
      # objects that have not yet been queried. For objects that have already
      # been queried the object is returned from the cache.
      def collection_objects_for_ids(collection, ids)
        if RequestStore.active?
          ids = ids.map(&:to_i)
          cache = collection_cache[collection_cache_key(collection)]
          to_query = ids - cache.keys

          unless to_query.empty?
            collection.where(id: to_query).each { |row| cache[row.id] = row }
          end

          cache.values_at(*ids).compact
        else
          collection.where(id: ids)
        end
      end

      # Returns the cache key to use for a collection.
      def collection_cache_key(collection)
        collection.respond_to?(:model) ? collection.model : collection
      end

      # Processes the list of HTML documents and returns an Array containing all
      # the references.
      def process(documents)
        type = self.class.reference_type
        reference_options = self.class.reference_options

        nodes = documents.flat_map do |document|
          Querying.css(document, "a[data-reference-type='#{type}'].gfm", reference_options).to_a
        end

        gather_references(nodes)
      end

      # Gathers the references for the given HTML nodes.
      def gather_references(nodes)
        nodes = nodes_user_can_reference(current_user, nodes)
        nodes = nodes_visible_to_user(current_user, nodes)

        referenced_by(nodes)
      end

      # Returns a Hash containing the projects for a given list of HTML nodes.
      #
      # The returned Hash uses the following format:
      #
      #     { node => project }
      #
      def projects_for_nodes(nodes)
        @projects_for_nodes ||=
          grouped_objects_for_nodes(nodes, Project, 'data-project')
      end

      def can?(user, permission, subject = :global)
        Ability.allowed?(user, permission, subject)
      end

      def find_projects_for_hash_keys(hash)
        collection_objects_for_ids(Project, hash.keys)
      end

      private

      attr_reader :context

      def current_user
        context.current_user
      end

      # When a feature is disabled or visible only for
      # team members we should not allow team members
      # see reference comments.
      # Override this method on subclasses
      # to check if user can read resource
      def can_read_reference?(user, ref_project, node)
        raise NotImplementedError
      end

      def lazy(&block)
        Gitlab::Lazy.new(&block)
      end

      def collection_cache
        RequestStore[:banzai_collection_cache] ||= Hash.new do |hash, key|
          hash[key] = {}
        end
      end
    end
  end
end
