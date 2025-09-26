# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Cop that detects inefficient patterns using ActiveRecord's `exists?`, `present?`,
      # or `blank?` in a suboptimal way.
      # @example
      #   # bad
      #   users.present?
      #
      #   # good
      #   users.any?
      class ARExistsAndPresentBlank < RuboCop::Cop::Base
        def message_present(ivar)
          "Avoid `#{ivar}.present?`, because it will generate database query 'Select TABLE.*' which is expensive. "\
          "Suggest to use `#{ivar}.any?` to replace `#{ivar}.present?`"
        end

        def message_blank(ivar)
          "Avoid `#{ivar}.blank?`, because it will generate database query 'Select TABLE.*' which is expensive. "\
          "Suggest to use `#{ivar}.empty?` to replace `#{ivar}.blank?`"
        end

        # @!method exists_match(node)
        def_node_matcher :exists_match, <<~PATTERN
          (send (ivar $_) :exists?)
        PATTERN

        # @!method present_match(node)
        def_node_matcher :present_match, <<~PATTERN
          (send (ivar $_) :present?)
        PATTERN

        # @!method blank_match(node)
        def_node_matcher :blank_match, <<~PATTERN
          (send (ivar $_) :blank?)
        PATTERN

        def file_name(node)
          node.source_range.source_buffer.name
        end

        def in_haml_file?(node)
          file_name(node).end_with?('.haml.rb')
        end

        def on_send(node)
          return unless in_haml_file?(node)

          ivar_present = present_match(node)
          ivar_blank = blank_match(node)
          return unless ivar_present || ivar_blank

          node.each_ancestor(:begin) do |begin_node|
            begin_node.each_descendant do |n|
              ivar_exists = exists_match(n)
              next unless ivar_exists

              add_offense(node, message: message_present(ivar_exists)) if ivar_exists == ivar_present
              add_offense(node, message: message_blank(ivar_exists)) if ivar_exists == ivar_blank
            end
          end
        end
      end
    end
  end
end
