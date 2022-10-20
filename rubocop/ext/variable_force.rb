# frozen_string_literal: true

module RuboCop
  module Ext
    module VariableForce
      def scanned_node?(node)
        scanned_nodes.include?(node)
      end

      def scanned_nodes
        @scanned_nodes ||= Set.new.compare_by_identity
      end
    end
  end
end

RuboCop::Cop::VariableForce.prepend RuboCop::Ext::VariableForce
