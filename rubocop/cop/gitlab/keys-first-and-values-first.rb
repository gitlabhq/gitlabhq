# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      class KeysFirstAndValuesFirst < RuboCop::Cop::Cop
        FIRST_PATTERN = /\Afirst\z/.freeze

        def message(used_method)
          <<~MSG
          Don't use `.keys.first` and `.values.first`.
          Instead use `.each_key.first` and `.each_value.first` (or `.first.first` and `first.second`)

          This will reduce memory usage and execution time.
          MSG
        end

        def on_send(node)
          if find_on_keys_or_values?(node)
            add_offense(node, location: :selector, message: message(node.method_name))
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            replace_with = if node.descendants.first.method_name == :values
                             '.each_value'
                           elsif node.descendants.first.method_name == :keys
                             '.each_key'
                           else
                             throw("Expect '.values.first' or '.keys.first', but get #{node.descendants.first.method_name}.first") # rubocop:disable Cop/BanCatchThrow
                           end

            upto_including_keys_or_values = node.descendants.first.source_range
            before_keys_or_values = node.descendants[1].source_range
            range_to_replace = node.source_range
                                  .with(begin_pos: before_keys_or_values.end_pos,
                                        end_pos: upto_including_keys_or_values.end_pos)
            corrector.replace(range_to_replace, replace_with)
          end
        end

        def find_on_keys_or_values?(node)
          chained_on_node = node.descendants.first
          node.method_name.to_s =~ FIRST_PATTERN &&
              chained_on_node.is_a?(RuboCop::AST::SendNode) &&
              [:keys, :values].include?(chained_on_node.method_name) &&
              node.descendants[1]
        end

        def method_name_for_node(node)
          children[1].to_s
        end
      end
    end
  end
end
