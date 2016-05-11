module Banzai
  module ReferenceParser
    # Base class for reference parsing classes.
    #
    # Each reference parser class should extend this class and implement the
    # instance method `referenced_by`. This method takes an Array of HTML nodes
    # to process and should return an Array of references (e.g. an Array of User
    # objects).
    #
    # Each parser should also specify its reference type by calling
    # `self.reference_type = ...` in the body of the class. The value of this
    # method should be a symbol such as `:issue` or `:merge_request`. For
    # example:
    #
    #     class IssueParser < Parser
    #       self.reference_type = :issue
    #     end
    #
    # The reference type is used to determine what nodes to pass to the
    # `referenced_by` method.
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
    class Parser
      def self.reference_type=(type)
        @reference_type = type.to_sym
      end

      def self.reference_type
        @reference_type
      end

      def initialize(project = nil, current_user = nil, author = nil)
        @project = project
        @current_user = current_user
        @author = author
      end

      # Returns all the nodes containing references that the user can refer to.
      def nodes_user_can_reference(current_user, nodes)
        nodes
      end

      # Returns all the nodes that are visible to the given user.
      def nodes_visible_to_user(user, nodes)
        projects = lazy { projects_for_nodes(nodes) }
        project_attr = 'data-project'

        nodes.select do |node|
          if node.has_attribute?(project_attr)
            node_id = node.attr(project_attr).to_i

            if project && project.id == node_id
              true
            else
              Ability.abilities.allowed?(user, :read_project, projects[node_id])
            end
          else
            true
          end
        end
      end

      def referenced_by(nodes)
        raise NotImplementedError, "#{self.class} does not implement #{__method__}"
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

      # Returns a Hash containing objects for an attribute grouped per their
      # IDs.
      #
      # The returned Hash uses the following format:
      #
      #     { id value => row }
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
        ids = unique_attribute_values(nodes, attribute)

        collection.where(id: ids).each_with_object({}) do |row, hash|
          hash[row.id] = row
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

      # Processes the list of HTML documents and returns an Array containing all
      # the references.
      def process(documents)
        type = self.class.reference_type
        nodes = []

        documents.each do |document|
          nodes.concat(
            Querying.css(document, "a[data-reference-type='#{type}'].gfm")
          )
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
      #     { project ID => project }
      #
      def projects_for_nodes(nodes)
        @projects_for_nodes ||= {}

        @projects_for_nodes[nodes] ||=
          grouped_objects_for_nodes(nodes, Project, 'data-project')
      end

      private

      def current_user
        @current_user
      end

      def project
        @project
      end

      def lazy(&block)
        Gitlab::Lazy.new(&block)
      end
    end
  end
end
