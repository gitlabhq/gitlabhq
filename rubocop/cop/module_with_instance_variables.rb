module RuboCop
  module Cop
    class ModuleWithInstanceVariables < RuboCop::Cop::Cop
      MSG = <<~EOL.freeze
        Do not use instance variables in a module. Please read this
        for the rationale behind it:

        doc/development/module_with_instance_variables.md

        If you think the use for this is fine, please just add:
        # rubocop:disable Cop/ModuleWithInstanceVariables
      EOL

      def on_module(node)
        return if
          rails_helper?(node) || rails_mailer?(node) || spec_helper?(node)

        check_method_definition(node)

        # Not sure why some module would have an extra begin wrapping around
        node.each_child_node(:begin) do |begin_node|
          check_method_definition(begin_node)
        end
      end

      private

      # We ignore Rails helpers right now because it's hard to workaround it
      def rails_helper?(node)
        node.source_range.source_buffer.name =~
          %r{app/helpers/\w+_helper.rb\z}
      end

      # We ignore Rails mailers right now because it's hard to workaround it
      def rails_mailer?(node)
        node.source_range.source_buffer.name =~
          %r{app/mailers/emails/}
      end

      # We ignore spec helpers because it usually doesn't matter
      def spec_helper?(node)
        node.source_range.source_buffer.name =~
          %r{spec/support/|features/steps/}
      end

      def check_method_definition(node)
        node.each_child_node(:def) do |definition|
          # We allow this pattern:
          # def f
          #   @f ||= true
          # end
          if only_ivar_or_assignment?(definition)
            # We don't allow if any other ivar is used
            definition.each_descendant(:ivar) do |offense|
              add_offense(offense, :expression)
            end
          else
            definition.each_descendant(:ivar, :ivasgn) do |offense|
              add_offense(offense, :expression)
            end
          end
        end
      end

      def only_ivar_or_assignment?(definition)
        node = definition.child_nodes.last

        definition.child_nodes.size == 2 &&
          node.or_asgn_type? && node.child_nodes.first.ivasgn_type?
      end
    end
  end
end
