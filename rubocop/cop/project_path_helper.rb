module RuboCop
  module Cop
    class ProjectPathHelper < RuboCop::Cop::Cop
      MSG = 'Use short project path helpers without explicitly passing the namespace: ' \
        '`foo_project_bar_path(project, bar)` instead of ' \
        '`foo_namespace_project_bar_path(project.namespace, project, bar)`.'.freeze

      METHOD_NAME_PATTERN = /\A([a-z_]+_)?namespace_project(?:_[a-z_]+)?_(?:url|path)\z/.freeze

      def on_send(node)
        return unless method_name(node).to_s =~ METHOD_NAME_PATTERN

        namespace_expr, project_expr = arguments(node)
        return unless namespace_expr && project_expr

        return unless namespace_expr.type == :send
        return unless method_name(namespace_expr) == :namespace
        return unless receiver(namespace_expr) == project_expr

        add_offense(node, location: :selector)
      end

      def autocorrect(node)
        helper_name = method_name(node).to_s.sub('namespace_project', 'project')

        arguments = arguments(node)
        arguments.shift # Remove namespace argument

        replacement = "#{helper_name}(#{arguments.map(&:source).join(', ')})"

        lambda do |corrector|
          corrector.replace(node.source_range, replacement)
        end
      end

      private

      def receiver(node)
        node.children[0]
      end

      def method_name(node)
        node.children[1]
      end

      def arguments(node)
        node.children[2..-1]
      end
    end
  end
end
