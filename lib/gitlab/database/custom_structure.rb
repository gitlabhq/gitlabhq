# frozen_string_literal: true

module Gitlab
  module Database
    class CustomStructure
      CUSTOM_DUMP_FILE = 'db/gitlab_structure.sql'

      def dump
        File.open(self.class.custom_dump_filepath, 'wb') do |io|
          io << "-- this file tracks custom GitLab data, such as foreign keys referencing partitioned tables\n"
          io << "-- more details can be found in the issue: https://gitlab.com/gitlab-org/gitlab/-/issues/201872\n\n"

          dump_partitioned_foreign_keys(io) if partitioned_foreign_keys_exist?
        end
      end

      def self.custom_dump_filepath
        Rails.root.join(CUSTOM_DUMP_FILE)
      end

      private

      def dump_partitioned_foreign_keys(io)
        io << "COPY partitioned_foreign_keys (#{partitioned_fk_columns.join(", ")}) FROM STDIN;\n"

        PartitioningMigrationHelpers::PartitionedForeignKey.find_each do |fk|
          io << fk.attributes.values_at(*partitioned_fk_columns).join("\t") << "\n"
        end
        io << "\\.\n"
      end

      def partitioned_foreign_keys_exist?
        return false unless PartitioningMigrationHelpers::PartitionedForeignKey.table_exists?

        PartitioningMigrationHelpers::PartitionedForeignKey.exists?
      end

      def partitioned_fk_columns
        @partitioned_fk_columns ||= PartitioningMigrationHelpers::PartitionedForeignKey.column_names
      end
    end
  end
end
