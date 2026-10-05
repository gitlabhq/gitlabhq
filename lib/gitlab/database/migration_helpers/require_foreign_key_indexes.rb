# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      # Refuses to drop an index while it is the last one supporting a foreign
      # key, since FK checks on the referenced table would then scan the table.
      module RequireForeignKeyIndexes
        extend ActiveSupport::Concern

        def remove_concurrent_index(table_name, column_name, options = {})
          # Defer to the base implementation's more specific transaction/partition errors.
          unless transaction_open? || partition?(table_name)
            assert_index_not_last_supporting_foreign_key!(
              table_name,
              find_index_definition(table_name, column_name: column_name, name: options[:name])
            )
          end

          super
        end

        def remove_concurrent_index_by_name(table_name, index_name, options = {})
          name = index_name.is_a?(Hash) ? index_name[:name] : index_name

          if name.present? && !transaction_open? && !partition?(table_name)
            assert_index_not_last_supporting_foreign_key!(
              table_name,
              find_index_definition(table_name, name: name)
            )
          end

          super
        end

        def prepare_async_index_removal(table_name, column_name, options = {})
          index_name = options[:name]

          if index_name.present?
            assert_index_not_last_supporting_foreign_key!(
              table_name,
              find_index_definition(table_name, name: index_name)
            )
          end

          super
        end

        private

        def find_index_definition(table_name, column_name: nil, name: nil)
          indexes = connection.indexes(table_name)
          return indexes.find { |index| index.name == name.to_s } if name

          columns = Array.wrap(column_name).map(&:to_s)
          matches = indexes.select { |index| index.columns == columns }

          # With multiple matches remove_index refuses with its own error; let it win.
          matches.first if matches.one?
        end

        def assert_index_not_last_supporting_foreign_key!(table_name, index)
          Gitlab::Database::ForeignKeyIndexSupport.new(connection)
            .assert_index_not_last_supporting_foreign_key!(table_name, index)
        end
      end
    end
  end
end
