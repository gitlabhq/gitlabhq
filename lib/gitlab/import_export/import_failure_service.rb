# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ImportFailureService
      RETRIABLE_EXCEPTIONS = [GRPC::DeadlineExceeded, ActiveRecord::QueryCanceled].freeze

      attr_reader :importable

      def initialize(importable)
        @importable = importable
        @association = importable.association(:import_failures)
      end

      def with_retry(action:, relation_key: nil, relation_index: nil)
        on_retry = ->(exception, retry_count, *_args) do
          log_import_failure(
            source: action,
            relation_key: relation_key,
            relation_index: relation_index,
            exception: exception,
            retry_count: retry_count)
        end

        Retriable.with_context(:relation_import, on_retry: on_retry) do
          yield
        end
      end

      def log_import_failure(
        source:, exception:, relation_key: nil, relation_index: nil, retry_count: 0, external_identifiers: {})
        attributes = {
          relation_index: relation_index,
          source: source,
          retry_count: retry_count,
          importable_column_name => importable.id
        }

        Gitlab::ErrorTracking.track_exception(
          exception,
          attributes.merge(relation_name: relation_key)
        )

        ImportFailure.create(
          attributes.merge(
            exception_class: exception.class.to_s,
            exception_message: exception.message.truncate(255),
            correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id,
            relation_key: relation_key,
            external_identifiers: external_identifiers
          )
        )
      end

      private

      def importable_column_name
        @importable_column_name ||= @association.reflection.foreign_key.to_sym
      end
    end
  end
end
