# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module Migration
      # Cop that prevents introducing `encrypted_*` columns (used by the `attr_encrypted` gem).
      #
      # @example
      #
      #   # bad
      #   class CreateAuditEventsInstanceAmazonS3Configurations < ActiveRecord::Migration[6.0]
      #     def change
      #       create_table :audit_events_instance_amazon_s3_configurations do |t|
      #         t.binary :encrypted_secret_access_key
      #         t.binary :encrypted_secret_access_key_iv
      #       end
      #     end
      #   end
      #
      #   # good
      #   class CreateAuditEventsInstanceAmazonS3Configurations < ActiveRecord::Migration[6.0]
      #     def change
      #       create_table :audit_events_instance_amazon_s3_configurations do |t|
      #         t.jsonb :secret_access_key
      #       end
      #     end
      #   end
      #
      #   # bad
      #   class CreateAuditEventsInstanceAmazonS3Configurations < ActiveRecord::Migration[6.0]
      #     def change
      #       add_column :audit_events_instance_amazon_s3_configurations, :encrypted_secret_access_key, :binary
      #       add_column :audit_events_instance_amazon_s3_configurations, :encrypted_secret_access_key_iv, :binary
      #     end
      #   end
      #
      #   # good
      #   class CreateAuditEventsInstanceAmazonS3Configurations < ActiveRecord::Migration[6.0]
      #     def change
      #       add_column :audit_events_instance_amazon_s3_configurations, :secret_access_key, :jsonb
      #     end
      #   end
      class PreventAddingAttrEncryptedColumns < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "Do not introduce `%<wrong_column>s` (`attr_encrypted` column), introduce a single " \
          "`%<correct_column>s` column with type `:jsonb` instead. " \
          "See https://docs.gitlab.com/development/migration_style_guide/#encrypted-attributes"

        ADD_COLUMN_PATTERN = <<~PATTERN
          `$(send nil? {:add_column :change_column_type_concurrently} sym $({sym|const nil?} _column_name) (sym :binary))
        PATTERN

        CREATE_TABLE_PATTERN = <<~PATTERN
          `(block
            (send _ :create_table sym)
            args
            `$(send lvar :binary $({sym|const nil?} _column_name) ...)
          )
        PATTERN

        # @!method attr_encrypted_columns(node) {yield(send_node, column_name)}
        #   @param [RuboCop::AST::Node] node
        def_node_matcher :attr_encrypted_columns, <<~PATTERN
          (def !:down args {#{ADD_COLUMN_PATTERN} | #{CREATE_TABLE_PATTERN}})
        PATTERN

        def on_def(node)
          attr_encrypted_columns(node) do |send_node, wrong_column|
            wrong_column = resolve_constant(wrong_column)
            next unless attr_encrypted_column?(wrong_column)

            correct_column = derive_correct_column_name(wrong_column)
            register_offense(send_node, wrong_column, correct_column)
          end
        end

        private

        def derive_correct_column_name(wrong_column)
          wrong_column.to_s.delete_prefix('encrypted_').delete_suffix('_iv')
        end

        def register_offense(node, wrong_column, correct_column)
          add_offense(
            node.loc.selector,
            message: format(MSG, wrong_column: wrong_column, correct_column: correct_column)
          )
        end

        def attr_encrypted_column?(column_name)
          column_name.start_with?('encrypted_')
        end

        def resolve_constant(node)
          return node.value unless node.const_type?

          node.ancestors.each do |ancestor|
            constant = find_constant(ancestor, node.short_name)
            return constant.expression.value if constant
          end
        end

        def find_constant(node, name)
          return node.expression.value if constant_assignment_matches?(node, name)

          node.children.find do |child|
            next unless valid_node?(child)

            find_constant(child, name)
          end
        end

        def constant_assignment_matches?(node, name)
          node.casgn_type? && node.name == name
        end

        def valid_node?(node)
          node.is_a?(RuboCop::AST::Node)
        end
      end
    end
  end
end
