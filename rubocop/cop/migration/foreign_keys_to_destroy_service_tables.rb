# frozen_string_literal: true

require 'yaml'
require_relative '../../migration_helpers'
require_relative '../../../lib/gitlab/database/tables_with_destroy_services'

module RuboCop
  module Cop
    module Migration
      # Flags migrations adding a foreign key to a table deleted through a
      # dedicated destroy service (e.g. `projects` via `Projects::DestroyService`).
      # The ON DELETE CASCADE is only a backstop for manual admin deletes; the
      # destroy service must clean up dependent records itself, since cascades
      # skip application logic such as object storage removal. Update the
      # service, then disable this cop inline with a comment pointing at the
      # handling.
      #
      # Not flagged: declared sharding keys, which sharding_key_spec.rb already
      # mandates and validates, and tables documented in db/docs/deleted_tables.
      #
      # @example
      #   # bad
      #   add_concurrent_foreign_key :widgets, :projects, column: :project_id
      #
      #   # good
      #   # Once Projects::DestroyService deletes widgets:
      #   add_concurrent_foreign_key :widgets, :projects, column: :project_id # inline disable with reason
      class ForeignKeysToDestroyServiceTables < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = 'Records of the `%{table}` table are deleted through %{service}, so the destroy service ' \
          'must be updated to handle these new dependent records. The ON DELETE CASCADE on this ' \
          'foreign key is only a backstop for a self-managed admin who manually deletes a `%{table}` ' \
          'row from the database. Once %{service} handles the cleanup, disable this cop on this line ' \
          'with a comment stating where it\'s handled.'

        TABLE_BLOCK_METHODS = %i[create_table change_table].freeze

        # @!method standalone_foreign_key_target(node)
        def_node_matcher :standalone_foreign_key_target, <<~PATTERN
          (send nil? {:add_foreign_key :add_concurrent_foreign_key :add_concurrent_partitioned_foreign_key}
            _ ${({sym str} _) (const nil? _)} ...)
        PATTERN

        # @!method table_block_foreign_key_target(node)
        def_node_matcher :table_block_foreign_key_target, <<~PATTERN
          (send (lvar _) :foreign_key ${({sym str} _) (const nil? _)} ...)
        PATTERN

        # @!method table_constant(node)
        def_node_matcher :table_constant, <<~PATTERN
          (casgn nil? $_ ({sym str} $_))
        PATTERN

        # @!method reference_definition(node)
        def_node_matcher :reference_definition, <<~PATTERN
          {
            (send (lvar _) {:references :belongs_to} ({sym str} $_) $(hash ...))
            (send nil? :add_reference _ ({sym str} $_) $(hash ...))
          }
        PATTERN

        # @!method foreign_key_option(node)
        def_node_search :foreign_key_option, <<~PATTERN
          (pair (sym :foreign_key) ${hash true})
        PATTERN

        # @!method to_table_option(node)
        def_node_search :to_table_option, <<~PATTERN
          (pair (sym :to_table) ${({sym str} _) (const nil? _)})
        PATTERN

        # @!method foreign_key_source(node)
        def_node_matcher :foreign_key_source, <<~PATTERN
          (send nil? {:add_foreign_key :add_concurrent_foreign_key :add_concurrent_partitioned_foreign_key
            :add_reference}
            ${({sym str} _) (const nil? _)} ...)
        PATTERN

        # @!method column_option(node)
        def_node_search :column_option, <<~PATTERN
          (pair (sym :column) ({sym str} $_))
        PATTERN

        # @!method foreign_key_from_list(node)
        def_node_matcher :foreign_key_from_list, <<~PATTERN
          (send nil? {:add_foreign_key :add_concurrent_foreign_key :add_concurrent_partitioned_foreign_key}
            ${(send (lvar _) :[] (sym _)) ({sym str} _) (const nil? _)}
            $(send (lvar _) :[] (sym _)) ...)
        PATTERN

        # @!method foreign_key_list_constant(node)
        def_node_matcher :foreign_key_list_constant, <<~PATTERN
          (casgn nil? $_ $(array (hash ...) ...))
        PATTERN

        # @!method column_index_option(node)
        def_node_search :column_index_option, <<~PATTERN
          (pair (sym :column) (send (lvar _) :[] (sym $_)))
        PATTERN

        def self.destroy_service_tables
          ::Gitlab::Database::TablesWithDestroyServices.tables_to_services
        end

        def self.sharding_key_columns(table)
          @sharding_key_columns ||= {}
          @sharding_key_columns.fetch(table) do
            @sharding_key_columns[table] = load_sharding_key_columns(table)
          end
        end

        def self.load_sharding_key_columns(table)
          path = File.expand_path("../../../db/docs/#{table}.yml", __dir__)
          return [] unless File.exist?(path)

          doc = YAML.safe_load_file(path)
          ((doc['sharding_key'] || {}).keys + (doc['desired_sharding_key'] || {}).keys).map(&:to_s)
        end

        def self.removed_table?(table)
          File.exist?(File.expand_path("../../../db/docs/deleted_tables/#{table}.yml", __dir__))
        end

        def on_new_investigation
          super
          @constant_tables = {}
          @constant_foreign_key_lists = {}
          processed_source.ast&.each_descendant(:casgn) do |node|
            name, table = table_constant(node)
            @constant_tables[name] = table if name

            name, array = foreign_key_list_constant(node)
            @constant_foreign_key_lists[name] = literal_hash_entries(array) if name
          end
        end

        def on_send(node)
          return unless time_enforced?(node)
          return if node.each_ancestor(:def).any? { |definition| definition.method?(:down) }
          return if check_foreign_key_list(node)

          table = target_table(node)
          return unless table

          services = self.class.destroy_service_tables[table.to_s]
          return unless services
          return if sharding_key_foreign_key?(node, table)
          return if removed_table_foreign_key?(node)

          add_offense(node.loc.selector, message: format(MSG, table: table, service: services.join(' or ')))
        end
        alias_method :on_csend, :on_send

        private

        # Handles foreign keys defined as an array of hashes iterated with
        # each, e.g. FOREIGN_KEYS.each { |fk| add_concurrent_foreign_key(
        # fk[:source_table], fk[:target_table], column: fk[:column]) }.
        # Returns true when the call takes its target from a hash index, so
        # the literal/constant path is skipped.
        def check_foreign_key_list(node)
          source_node, target_node = foreign_key_from_list(node)
          return false unless target_node

          entries = constant_list_for(node, target_node)
          return true unless entries

          target_key = target_node.children[2].value
          entries.each do |entry|
            check_list_entry(node, entry, source_value(source_node, entry), target_key)
          end

          true
        end

        def constant_list_for(node, index_node)
          block_argument = index_node.children[0].children[0]
          block = node.each_ancestor(:block).find do |ancestor|
            ancestor.method?(:each) &&
              ancestor.receiver&.const_type? &&
              ancestor.arguments.one? && ancestor.first_argument.name == block_argument
          end
          return unless block

          @constant_foreign_key_lists[block.receiver.short_name]
        end

        def source_value(source_node, entry)
          if source_node.send_type?
            entry[source_node.children[2].value]
          else
            resolve_table(source_node)
          end
        end

        def check_list_entry(node, entry, source, target_key)
          target = entry[target_key]
          return unless target

          services = self.class.destroy_service_tables[target.to_s]
          return unless services

          column = column_option(node).first
          column ||= (key = column_index_option(node).first) && entry[key]
          if source
            return if column && self.class.sharding_key_columns(source.to_s).include?(column.to_s)
            return if self.class.removed_table?(source.to_s)
          end

          add_offense(node.loc.selector, message: format(MSG, table: target, service: services.join(' or ')))
        end

        def literal_hash_entries(array)
          array.children.filter_map do |hash|
            next unless hash.hash_type?

            hash.pairs.each_with_object({}) do |pair, entry|
              next unless pair.key.sym_type?
              next unless pair.value.type?(:sym, :str)

              entry[pair.key.value] = pair.value.value
            end
          end
        end

        def target_table(node)
          target = standalone_foreign_key_target(node) || table_block_foreign_key_target(node)
          return resolve_table(target) if target

          name, options = reference_definition(node)
          return unless options

          foreign_key = foreign_key_option(options).first
          return unless foreign_key

          if foreign_key.hash_type?
            to_table = to_table_option(foreign_key).first
            return resolve_table(to_table) if to_table
          end

          pluralize(name)
        end

        # Unqualified constants resolve from same-file assignments; anything
        # unresolvable stays unflagged.
        def resolve_table(node)
          case node.type
          when :sym, :str then node.value
          when :const then @constant_tables[node.short_name]
          end
        end

        def sharding_key_foreign_key?(node, target)
          source = source_table(node)
          return false unless source

          column = foreign_key_column(node, target)
          self.class.sharding_key_columns(source.to_s).include?(column.to_s)
        end

        # Tables in db/docs/deleted_tables were renamed or dropped after the
        # migration ran; such historical migrations cannot be fixed anymore.
        def removed_table_foreign_key?(node)
          source = source_table(node)

          source && self.class.removed_table?(source.to_s)
        end

        def source_table(node)
          source = foreign_key_source(node)
          return resolve_table(source) if source

          block = node.each_ancestor(:block).find do |ancestor|
            TABLE_BLOCK_METHODS.include?(ancestor.method_name)
          end
          first_argument = block&.send_node&.first_argument
          resolve_table(first_argument) if first_argument
        end

        def foreign_key_column(node, target)
          name, _options = reference_definition(node)
          return "#{name}_id" if name

          column_option(node).first || "#{singularize(target)}_id"
        end

        def singularize(name)
          name = name.to_s
          return "#{name[0..-4]}y" if name.end_with?('ies')
          return name.delete_suffix('es') if name.match?(/(?:ch|sh|x|z)es\z/)

          name.delete_suffix('s')
        end

        # Common English plural rules; anything else must use `to_table:`.
        def pluralize(name)
          name = name.to_s
          return name if name.end_with?('s')
          return "#{name[0..-2]}ies" if name.match?(/[^aeiou]y\z/)
          return "#{name}es" if name.match?(/(?:ch|sh|x|z)\z/)

          "#{name}s"
        end
      end
    end
  end
end
