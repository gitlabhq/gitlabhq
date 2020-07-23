# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlAdapter
      module DumpSchemaVersionsMixin
        extend ActiveSupport::Concern

        def dump_schema_information # :nodoc:
          versions = schema_migration.all_versions
          Gitlab::Database::SchemaVersionFiles.touch_all(versions) if versions.any?

          nil
        end
      end
    end
  end
end
