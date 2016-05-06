module Banzai
  module ReferenceParser
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
        projects = projects_for_nodes(nodes)
        project_attr = 'data-project'

        nodes.select do |node|
          if node.has_attribute?(project_attr)
            node_project = projects[node.attr(project_attr).to_i]

            if node_project && node_project.id == project.id
              true
            else
              Ability.abilities.allowed?(user, :read_project, node_project)
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
        ids = []

        nodes.each do |node|
          ids << node.attr(attribute).to_i if node.has_attribute?(attribute)
        end

        collection.where(id: ids).each_with_object({}) do |row, hash|
          hash[row.id] = row
        end
      end

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

      def gather_references(nodes)
        nodes = nodes_user_can_reference(current_user, nodes)
        nodes = nodes_visible_to_user(current_user, nodes)

        referenced_by(nodes)
      end

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
    end
  end
end
