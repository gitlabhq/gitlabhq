# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class ARCountEach < RuboCop::Cop::Base
        def message(ivar)
          "If #{ivar} is AR relation, avoid `#{ivar}.count ...; #{ivar}.each... `, this will trigger two queries. " \
          "Use `#{ivar}.load.size ...; #{ivar}.each... ` instead. If #{ivar} is an array, try to use #{ivar}.size."
        end

        def_node_matcher :count_match, <<~PATTERN
          (send (ivar $_) :count)
        PATTERN

        def_node_matcher :each_match, <<~PATTERN
          (send (ivar $_) :each)
        PATTERN

        def file_name(node)
          node.location.expression.source_buffer.name
        end

        def in_haml_file?(node)
          file_name(node).end_with?('.haml.rb')
        end

        def on_send(node)
          return unless in_haml_file?(node)

          ivar_count = count_match(node)
          return unless ivar_count

          node.each_ancestor(:begin) do |begin_node|
            begin_node.each_descendant do |n|
              ivar_each = each_match(n)

              add_offense(node, message: message(ivar_count)) if ivar_each == ivar_count
            end
          end
        end
      end
    end
  end
end
