# frozen_string_literal: true

module Import
  module PlaceholderReferences
    class LoadService < BaseService
      BATCH_LIMIT = 500

      def initialize(import_source:, import_uid:)
        super(import_source: import_source, import_uid: import_uid)

        @processed_count = 0
        @error_count = 0
      end

      def execute
        log_info(message: 'Processing placeholder references')

        while (batch = next_batch).present?
          load!(batch)

          # End this loop if we know that we cleared the set earlier.
          # This prevents processing just a few records at a time if an import is simultaneously writing data to Redis.
          break if batch.size < BATCH_LIMIT
        end

        log_info(
          message: 'Processed placeholder references',
          processed_count: processed_count,
          error_count: error_count
        )

        success(processed_count: processed_count, error_count: error_count)
      end

      private

      attr_accessor :error_count, :processed_count

      def next_batch
        store.get(BATCH_LIMIT)
      end

      def load!(batch)
        to_load = batch.filter_map do |item|
          SourceUserPlaceholderReference.from_serialized(item)
        rescue JSON::ParserError, SourceUserPlaceholderReference::SerializationError => e
          log_error(item, e)
          nil
        end

        begin
          bulk_insert!(to_load)
        rescue ActiveRecord::RecordInvalid => e
          # We optimise for all records being valid and only filter for validity
          # when there was a problem
          to_load.reject! do |item|
            next false if item.valid?

            log_error(item.attributes, e)
            true
          end

          # Try again
          bulk_insert!(to_load)
        rescue ActiveRecord::InvalidForeignKey => e
          # This is an unrecoverable situation where we allow the error to clear the batch
          log_error(to_load, e)
        end

        clear_batch!(batch)
      end

      def bulk_insert!(to_load)
        Import::SourceUserPlaceholderReference.bulk_insert!(to_load)
      end

      def clear_batch!(batch)
        processed_count = batch.size

        self.processed_count += processed_count

        store.remove(batch)
      end

      def log_error(item, exception)
        super(
          message: 'Error processing placeholder reference',
          item: item,
          exception: {
            class: exception.class,
            message: exception.message
          }
        )

        self.error_count += 1
      end
    end
  end
end
