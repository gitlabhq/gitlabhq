# frozen_string_literal: true

module Gitlab
  module Database
    # Checks which `ignored_columns` definitions can be safely removed by
    # scanning the current schema for all `ApplicationRecord` descendants.
    class ObsoleteIgnoredColumns
      def initialize(base = ApplicationRecord)
        @base = base
      end

      def execute
        @base.descendants.filter_map do |klass|
          next if klass.abstract_class?

          safe_to_remove = ignored_columns_safe_to_remove_for(klass)
          next if safe_to_remove.empty?

          [klass.name, safe_to_remove]
        end.compact.sort_by(&:first)
      end

      private

      def ignored_columns_safe_to_remove_for(klass)
        ignores = ignored_and_not_present(klass).index_with do |col|
          klass.ignored_columns_details[col.to_sym]
        end

        ignores.select { |_, i| i&.safe_to_remove? }
      end

      def ignored_and_not_present(klass)
        ignored = klass.ignored_columns.map(&:to_s)
        return [] if ignored.empty?

        schema = klass.connection.schema_cache.columns_hash(klass.table_name)
        existing = schema.values.map(&:name)

        used = ignored & existing
        ignored - used
      end
    end
  end
end
