# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class ModuleWithInstanceVariables < RuboCop::Cop::Base
        MSG = <<~EOL
          Do not use instance variables in a module. Please read this
          for the rationale behind it:

          https://docs.gitlab.com/ee/development/module_with_instance_variables.html
        EOL

        def on_module(node)
          check_method_definition(node)

          # Not sure why some module would have an extra begin wrapping around
          node.each_child_node(:begin) do |begin_node|
            check_method_definition(begin_node)
          end
        end

        private

        def check_method_definition(node)
          node.each_child_node(:def) do |definition|
            # We allow this pattern:
            #
            #     def f
            #       @f ||= true
            #     end
            if only_ivar_or_assignment?(definition)
              # We don't allow if any other ivar is used
              definition.each_descendant(:ivar) do |offense|
                add_offense(offense)
              end
            # We allow initialize method and single ivar
            elsif !initialize_method?(definition) && !single_ivar?(definition)
              definition.each_descendant(:ivar, :ivasgn) do |offense|
                add_offense(offense)
              end
            end
          end
        end

        def only_ivar_or_assignment?(definition)
          node = definition.child_nodes.last

          definition.child_nodes.size == 2 &&
            node.or_asgn_type? && node.child_nodes.first.ivasgn_type?
        end

        def single_ivar?(definition)
          node = definition.child_nodes.last

          definition.child_nodes.size == 2 && node.ivar_type?
        end

        def initialize_method?(definition)
          definition.children.first == :initialize
        end
      end
    end
  end
end
