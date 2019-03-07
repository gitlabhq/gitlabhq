# frozen_string_literal: true

module Gitlab
  module GithubImport
    module BulkImporting
      # Builds and returns an Array of objects to bulk insert into the
      # database.
      #
      # enum - An Enumerable that returns the objects to turn into database
      #        rows.
      def build_database_rows(enum)
        enum.each_with_object([]) do |(object, _), rows|
          rows << build(object) unless already_imported?(object)
        end
      end

      # Bulk inserts the given rows into the database.
      def bulk_insert(model, rows, batch_size: 100)
        rows.each_slice(batch_size) do |slice|
          Gitlab::Database.bulk_insert(model.table_name, slice)
        end
      end
    end
  end
end
