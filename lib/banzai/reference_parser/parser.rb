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

      def referenced_by(node)
        raise NotImplementedError, "#{self.class} does not implement #{__method__}"
      end

      def process(document)
        refs = Set.new
        type = self.class.reference_type

        Querying.css(document, "a[data-reference-type='#{type}'].gfm").each do |node|
          gather_references(node).each do |ref|
            refs << ref
          end
        end

        refs = refs.to_a

        if ReferenceExtractor.lazy?
          refs
        else
          ReferenceExtractor.lazily(refs)
        end
      end

      def gather_references(node)
        return [] if author && !user_can_reference?(author, node)

        return [] unless user_can_see_reference?(current_user, node)

        referenced_by(node)
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
