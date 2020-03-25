# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlAdapter
      module SchemaVersionsCopyMixin
        extend ActiveSupport::Concern

        def dump_schema_information # :nodoc:
          versions = schema_migration.all_versions
          copy_versions_sql(versions) if versions.any?
        end

        private

        def copy_versions_sql(versions)
          sm_table = quote_table_name(schema_migration.table_name)

          sql = +"COPY #{sm_table} (version) FROM STDIN;\n"
          sql << versions.map { |v| Integer(v) }.sort.join("\n")
          sql << "\n\\.\n"

          sql
        end
      end
    end
  end
end
