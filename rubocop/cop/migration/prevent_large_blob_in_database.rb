# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents creating text columns with very large limits, which
      # effectively turn the relational database into blob storage.
      # The complementary `Migration/AddLimitToTextColumns` cop already enforces
      # that text columns have a limit; this cop caps how large that limit can be.
      # See https://gitlab.com/gitlab-org/gitlab/-/work_items/598499 for context.
      #
      # Text columns starting with `encrypted_` are very likely used by
      # `attr_encrypted` which controls the text length. Those columns are
      # exempt from this check.
      #
      # @example
      #   # bad - exceeds MaxSize
      #   create_table :examples do |t|
      #     t.text :content, limit: 131_072
      #   end
      #
      #   add_text_limit :examples, :content, 131_072
      #
      #   MAX = 131_072
      #   add_text_limit :examples, :content, MAX
      #
      #   # good
      #   create_table :examples do |t|
      #     t.text :content, limit: 1024
      #   end
      #
      #   add_text_limit :examples, :content, 1024
      #
      #   MAX = 1024
      #   add_text_limit :examples, :content, MAX
      class PreventLargeBlobInDatabase < RuboCop::Cop::Base
        include MigrationHelpers

        DEFAULT_MAX_SIZE = 4_096

        MSG = 'Text column limit of %{limit} exceeds the maximum allowed size of %{max} characters. ' \
          'Storing large blobs in the relational database is an antipattern that affects ' \
          'GitLab.com Data Growth Control efforts and self-managed customers. ' \
          'Consider using object storage for large content instead. ' \
          'See https://docs.gitlab.com/development/database/large_tables_limitations/#external-storage ' \
          'for guidance.'

        # @!method reverting?(node)
        def_node_matcher :reverting?, <<~PATTERN
          (def :down ...)
        PATTERN

        # @!method text_with_limit(node)
        def_node_matcher :text_with_limit, <<~PATTERN
          (send lvar :text $_attribute ... (hash <(pair (sym :limit) $_limit) ...>))
        PATTERN

        # @!method text_limit(node)
        def_node_matcher :text_limit, <<~PATTERN
          (send lvar :text_limit $_attribute $_limit ...)
        PATTERN

        # @!method add_text_limit(node)
        def_node_matcher :add_text_limit, <<~PATTERN
          (send nil? :add_text_limit _table $_attribute $_limit ...)
        PATTERN

        # @!method integer_constant(node, name:)
        def_node_matcher :integer_constant, <<~PATTERN
          (casgn nil? %name (int $_value))
        PATTERN

        # @!method symbol_constant(node, name:)
        def_node_matcher :symbol_constant, <<~PATTERN
          (casgn nil? %name (sym $_value))
        PATTERN

        def on_def(node)
          return unless in_migration?(node)
          return unless time_enforced?(node)
          return if reverting?(node)

          node.each_descendant(:send) do |send_node|
            check(send_node)
          end
        end

        private

        def check(node)
          attribute_node, limit_node = text_with_limit(node) || text_limit(node) || add_text_limit(node)
          return unless attribute_node

          column_name = symbol_value(attribute_node)
          return if column_name.nil? || encrypted_column?(column_name)

          limit = integer_value(limit_node)
          return if limit.nil? || limit <= max_size

          add_offense(node.loc.selector, message: format(MSG, limit: limit, max: max_size))
        end

        def encrypted_column?(name)
          name.to_s.start_with?('encrypted_')
        end

        # Resolves a symbol literal or a same-file symbol constant assignment
        # to its symbol value. Returns nil when the value cannot be statically
        # resolved (cross-file constants, expressions, etc.).
        def symbol_value(node)
          return node.value if node.sym_type?
          return unless node.const_type?

          processed_source.ast
            .each_descendant(:casgn)
            .filter_map { |casgn| symbol_constant(casgn, name: node.const_name.to_sym) }
            .first
        end

        # Resolves integer literals and same-file integer constant assignments.
        # Returns nil for everything else (cross-file constants, expressions, method calls).
        def integer_value(node)
          return node.value if node.int_type?
          return unless node.const_type?

          processed_source.ast
            .each_descendant(:casgn)
            .filter_map { |casgn| integer_constant(casgn, name: node.const_name.to_sym) }
            .first
        end

        def max_size
          cop_config['MaxSize'] || DEFAULT_MAX_SIZE
        end
      end
    end
  end
end
