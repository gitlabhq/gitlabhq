# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module CodeReuse
      # Cop that enforces various code reuse rules for Finders.
      class Finder < RuboCop::Cop::Base
        include CodeReuseHelpers

        IN_FINDER = 'Finders can not be used inside a Finder.'

        IN_MODEL_CLASS_METHOD =
          'Finders can not be used inside model class methods.'

        SUFFIX = 'Finder'

        def on_class(node)
          if in_finder?(node)
            check_finder(node)
          elsif in_model?(node)
            check_model_class_methods(node)
          end
        end

        def check_finder(node)
          disallow_send_to(node, SUFFIX, IN_FINDER)
        end

        def check_model_class_methods(node)
          each_class_method(node) do |def_node|
            disallow_send_to(def_node, SUFFIX, IN_MODEL_CLASS_METHOD)
          end
        end
      end
    end
  end
end
