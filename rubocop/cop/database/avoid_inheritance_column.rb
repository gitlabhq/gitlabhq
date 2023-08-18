# frozen_string_literal: true

module RuboCop
  module Cop
    module Database
      # Checks for `self.inheritance_column` usage, which is discouraged https://docs.gitlab.com/ee/development/database/single_table_inheritance.html
      class AvoidInheritanceColumn < RuboCop::Cop::Base
        MSG = "Do not use Single Table Inheritance https://docs.gitlab.com/ee/development/database/single_table_inheritance.html"

        def_node_search :inheritance_column_used?, <<~PATTERN
          (send (self) :inheritance_column= !(sym :_type_disabled))
        PATTERN

        def on_send(node)
          add_offense(node) if inheritance_column_used?(node)
        end
      end
    end
  end
end
