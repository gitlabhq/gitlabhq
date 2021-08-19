# frozen_string_literal: true

module Gitlab
  module GithubImport
    module BulkImporting
      attr_reader :project, :client

      # project - An instance of `Project`.
      # client - An instance of `Gitlab::GithubImport::Client`.
      def initialize(project, client)
        @project = project
        @client = client
      end

      # Builds and returns an Array of objects to bulk insert into the
      # database.
      #
      # enum - An Enumerable that returns the objects to turn into database
      #        rows.
      def build_database_rows(enum)
        rows = enum.each_with_object([]) do |(object, _), result|
          result << build(object) unless already_imported?(object)
        end

        log_and_increment_counter(rows.size, :fetched)

        rows
      end

      # Bulk inserts the given rows into the database.
      def bulk_insert(model, rows, batch_size: 100)
        rows.each_slice(batch_size) do |slice|
          Gitlab::Database.main.bulk_insert(model.table_name, slice) # rubocop:disable Gitlab/BulkInsert

          log_and_increment_counter(slice.size, :imported)
        end
      end

      def object_type
        raise NotImplementedError
      end

      private

      def log_and_increment_counter(value, operation)
        Gitlab::Import::Logger.info(
          import_type: :github,
          project_id: project.id,
          importer: self.class.name,
          message: "#{value} #{object_type.to_s.pluralize} #{operation}"
        )

        Gitlab::GithubImport::ObjectCounter.increment(
          project,
          object_type,
          operation,
          value: value
        )
      end
    end
  end
end
