module RuboCop
  module Cop
    # This cop prevents usage of 'redirect_to' in actions 'destroy' without specifying 'status'.
    # See https://gitlab.com/gitlab-org/gitlab-ce/issues/31840
    class RedirectWithStatus < RuboCop::Cop::Cop
      MSG = 'Do not use "redirect_to" without "status" in "destroy" action'.freeze

      def on_def(node)
        return unless in_controller?(node)
        return unless destroy?(node) || destroy_all?(node)

        node.each_descendant(:send) do |def_node|
          next unless redirect_to?(def_node)

          methods = []

          def_node.children.last.each_node(:pair) do |pair|
            methods << pair.children.first.children.first
          end

          add_offense(def_node, :selector) unless methods.include?(:status)
        end
      end

      private

      def in_controller?(node)
        node.location.expression.source_buffer.name.end_with?('_controller.rb')
      end

      def destroy?(node)
        node.children.first == :destroy
      end

      def destroy_all?(node)
        node.children.first == :destroy_all
      end

      def redirect_to?(node)
        node.children[1] == :redirect_to
      end
    end
  end
end
