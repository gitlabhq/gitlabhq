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

      def user_can_see_reference?(user, node)
        if node.has_attribute?('data-project')
          project_id = node.attr('data-project').to_i
          return true if project && project_id == project.id

          project = Project.find_by(id: project_id)
          Ability.abilities.allowed?(user, :read_project, project)
        else
          true
        end
      end

      def user_can_reference?(user, node)
        true
      end

      def referenced_by(nodes)
        raise NotImplementedError, "#{self.class} does not implement #{__method__}"
      end

      def gather_attributes_per_project(nodes, attribute)
        per_project = Hash.new { |hash, key| hash[key] = Set.new }

        nodes.each do |node|
          project_id = node.attr('data-project').to_i
          id = node.attr(attribute)

          per_project[project_id] << id if id
        end

        per_project
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
        selected = []

        nodes.each do |node|
          next if author && !user_can_reference?(author, node)
          next unless user_can_see_reference?(current_user, node)

          selected << node
        end

        referenced_by(selected)
      end

      private

      def current_user
        @current_user
      end

      def author
        @author
      end

      def project
        @project
      end
    end
  end
end
