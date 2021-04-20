# frozen_string_literal: true

module Gitlab
  module Database
    # Constructs queries of the form:
    #
    #   with cte(a, b, c) as (
    #     select * from (values (:x, :y, :z), (:q, :r, :s)) as t
    #     )
    #   update table set b = cte.b, c = cte.c where a = cte.a
    #
    # Which is useful if you want to update a set of records in a single query
    # but cannot express the update as a calculation (i.e. you have arbitrary
    # updates to perform).
    #
    # The requirements are that the table must have an ID column used to
    # identify the rows to be updated.
    #
    # Usage:
    #
    #  mapping = {
    #    issue_a => { title: 'This title', relative_position: 100 },
    #    issue_b => { title: 'That title', relative_position: 173 }
    #  }
    #
    #  ::Gitlab::Database::BulkUpdate.execute(%i[title relative_position], mapping)
    #
    # Note that this is a very low level tool, and operates on the raw column
    # values. Enums/state fields must be translated into their underlying
    # representations, for example, and no hooks will be called.
    #
    module BulkUpdate
      LIST_SEPARATOR = ', '

      class Setter
        include Gitlab::Utils::StrongMemoize

        def initialize(model, columns, mapping)
          @table_name = model.table_name
          @connection = model.connection
          @columns = self.class.column_definitions(model, columns)
          @mapping = self.class.value_mapping(mapping)
        end

        def update!
          if without_prepared_statement?
            # A workaround for https://github.com/rails/rails/issues/24893
            # When prepared statements are prevented (such as when using the
            # query counter or in omnibus by default), we cannot call
            # `exec_update`, since that will discard the bindings.
            connection.send(:exec_no_cache, sql, log_name, params) # rubocop: disable GitlabSecurity/PublicSend
          else
            connection.exec_update(sql, log_name, params)
          end
        end

        def self.column_definitions(model, columns)
          raise ArgumentError, 'invalid columns' if columns.blank? || columns.any? { |c| !c.is_a?(Symbol) }
          raise ArgumentError, 'cannot set ID' if columns.include?(:id)

          ([:id] | columns).map { |name| column_definition(model, name) }
        end

        def self.column_definition(model, name)
          definition = model.column_for_attribute(name)
          raise ArgumentError, "Unknown column: #{name}" unless definition.type

          definition
        end

        def self.value_mapping(mapping)
          raise ArgumentError, 'invalid mapping' if mapping.blank?
          raise ArgumentError, 'invalid mapping value' if mapping.any? { |_k, v| !v.is_a?(Hash) }

          mapping
        end

        private

        attr_reader :table_name, :connection, :columns, :mapping

        def log_name
          strong_memoize(:log_name) do
            "BulkUpdate #{table_name} #{columns.drop(1).map(&:name)}:#{mapping.size}"
          end
        end

        def params
          mapping.flat_map do |k, v|
            obj_id = k.try(:id) || k
            v = v.merge(id: obj_id)
            columns.map { |c| query_attribute(c, k, v.with_indifferent_access) }
          end
        end

        # A workaround for https://github.com/rails/rails/issues/24893
        # We need to detect if prepared statements have been disabled.
        def without_prepared_statement?
          strong_memoize(:without_prepared_statement) do
            connection.send(:without_prepared_statement?, [1]) # rubocop: disable GitlabSecurity/PublicSend
          end
        end

        def query_attribute(column, key, values)
          value = values[column.name]
          key[column.name] = value if key.try(:id) # optimistic update
          ActiveRecord::Relation::QueryAttribute.from_user(nil, value, ActiveModel::Type.lookup(column.type))
        end

        def values
          counter = 0
          typed = false

          mapping.map do |k, v|
            binds = columns.map do |c|
              bind = "$#{counter += 1}"
              # PG is not great at inferring types - help it for the first row.
              bind += "::#{c.sql_type}" unless typed
              bind
            end
            typed = true

            "(#{list_of(binds)})"
          end
        end

        def list_of(list)
          list.join(LIST_SEPARATOR)
        end

        def sql
          <<~SQL
            WITH cte(#{list_of(cte_columns)}) AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (VALUES #{list_of(values)})
            UPDATE #{table_name} SET #{list_of(updates)} FROM cte WHERE cte_id = id
          SQL
        end

        def column_names
          strong_memoize(:column_names) { columns.map(&:name) }
        end

        def cte_columns
          strong_memoize(:cte_columns) do
            column_names.map do |c|
              connection.quote_column_name("cte_#{c}")
            end
          end
        end

        def updates
          column_names.zip(cte_columns).drop(1).map do |dest, src|
            "#{connection.quote_column_name(dest)} = cte.#{src}"
          end
        end
      end

      def self.execute(columns, mapping, &to_class)
        raise ArgumentError if mapping.blank?

        entries_by_class = mapping.group_by { |k, v| block_given? ? to_class.call(k) : k.class }

        entries_by_class.each do |model, entries|
          Setter.new(model, columns, entries).update!
        end
      end
    end
  end
end
