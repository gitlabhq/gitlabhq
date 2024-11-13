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
        @validation_errors = []
      end

      # Builds and returns an Array of objects to bulk insert into the
      # database and array of validation errors if object is invalid.
      #
      # enum - An Enumerable that returns the objects to turn into database
      #        rows.
      def build_database_rows(enum)
        errors = []
        rows = enum.each_with_object([]) do |(object, _), result|
          next if already_imported?(object)

          attrs = build_attributes(object)
          build_record = model.new(attrs)

          if build_record.invalid?
            github_identifiers = github_identifiers(object)

            log_error(github_identifiers, build_record.errors.full_messages)
            errors << {
              validation_errors: build_record.errors,
              external_identifiers: github_identifiers
            }
            next
          end

          result << attrs
        end

        log_and_increment_counter(rows.size, :fetched)

        [rows, errors]
      end

      # Bulk inserts the given rows into the database.
      def bulk_insert(rows, batch_size: 100)
        inserted_ids = []
        rows.each_slice(batch_size) do |slice|
          inserted_ids += ApplicationRecord.legacy_bulk_insert(model.table_name, slice, return_ids: true) # rubocop:disable Gitlab/BulkInsert -- required

          log_and_increment_counter(slice.size, :imported)
        end

        inserted_ids
      end

      def object_type
        raise NotImplementedError
      end

      def bulk_insert_failures(errors)
        rows = errors.map do |error|
          correlation_id_value = Labkit::Correlation::CorrelationId.current_or_new_id

          {
            source: self.class.name,
            exception_class: 'ActiveRecord::RecordInvalid',
            exception_message: error[:validation_errors].full_messages.first.truncate(255),
            correlation_id_value: correlation_id_value,
            retry_count: nil,
            created_at: Time.zone.now,
            external_identifiers: error[:external_identifiers]
          }
        end

        project.import_failures.insert_all(rows)
      end

      private

      def log_and_increment_counter(value, operation)
        Logger.info(
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

      def log_error(github_identifiers, messages)
        Logger.error(
          project_id: project.id,
          importer: self.class.name,
          message: messages,
          external_identifiers: github_identifiers
        )
      end

      def github_identifiers(object)
        raise NotImplementedError
      end
    end
  end
end
