# frozen_string_literal: true

# RelationObjectSaver allows for an alternative approach to persisting
# objects during Project/Group Import which persists object's
# nested collection subrelations separately, in batches.
#
# Instead of the regular `relation_object.save!` that opens one db
# transaction for the object itself and all of its subrelations we
# separate collection subrelations from the object and save them
# in batches in smaller more frequent db transactions.
module Gitlab
  module ImportExport
    module Base
      class RelationObjectSaver
        include Gitlab::Utils::StrongMemoize

        BATCH_SIZE = 100
        # Default retry count for handling ActiveRecord::QueryCanceled
        MAX_RETRY_COUNT = 3
        # Factor to reduce batch size by when retrying after a timeout
        BATCH_SIZE_REDUCTION_FACTOR = 4

        MAX_EXCEPTION_RESCUE_COUNT = 20

        attr_reader :invalid_subrelations, :failed_subrelations

        # @param relation_object [Object] Object of a project/group, e.g. an issue
        # @param relation_key [String] Name of the object association to group/project, e.g. :issues
        # @param relation_definition [Hash] Object subrelations as defined in import_export.yml
        # @param importable [Project|Group] Project or group where relation object is getting saved to
        #
        # @example
        #   Gitlab::ImportExport::Base::RelationObjectSaver.new(
        #     relation_key: 'merge_requests',
        #     relation_object: #<MergeRequest id: root/mrs!1, notes: [#<Note id: nil, note: 'test', ...>, #<Note id: nil, noteL 'another note'>]>,
        #     relation_definition: {"metrics"=>{}, "award_emoji"=>{}, "notes"=>{"author"=>{}, ... }}
        #     importable: @importable
        #   ).execute
        def initialize(relation_object:, relation_key:, relation_definition:, importable:)
          @relation_object = relation_object
          @relation_key = relation_key
          @relation_definition = relation_definition
          @importable = importable
          @invalid_subrelations = []
          @failed_subrelations = []
          @exceptions_rescued = 0
        end

        def execute
          move_subrelations

          relation_object.save!

          save_subrelations
        end

        private

        attr_reader :relation_object, :relation_key, :relation_definition, :importable, :collection_subrelations

        # Processes all collection subrelations in configurable batches.
        #
        # Iterates through each collection subrelation that was extracted during
        # the move_subrelations step and processes them in batches of BATCH_SIZE
        # to prevent database timeouts.
        #
        # @example Processing a collection of 300 notes
        #   # Initial state: { "notes" => [note1, note2, ..., note300] }
        #   # Will create 3 batches of 100 records each:
        #   # - Batch 1: notes[1-100]
        #   # - Batch 2: notes[101-200]
        #   # - Batch 3: notes[201-300]
        #
        # rubocop:disable GitlabSecurity/PublicSend
        def save_subrelations
          collection_subrelations.each_pair do |relation_name, records|
            records.each_slice(BATCH_SIZE) do |batch|
              save_batch_with_retry(relation_name, batch)
            end
          end
        end

        # Saves a batch of records for a specific relation with retry logic.
        #
        # This method partitions the batch into valid and invalid records, processes
        # them accordingly, and implements retry logic for database timeouts.
        #
        # @example Processing a batch of records with potential timeout
        #   save_batch_with_retry("notes", batch_of_notes, 0)
        #   # If successful, all notes will be saved
        #   # If timeout occurs, will call process_with_smaller_batch_size
        def save_batch_with_retry(relation_name, batch, retry_count = 0)
          valid_records, invalid_records = batch.partition { |record| record.valid? }

          invalid_records.map! { |record| ::Import::ImportRecordPreparer.recover_invalid_record(record) }

          save_valid_records(relation_name, valid_records)

          save_potentially_invalid_records(relation_name, invalid_records)

          relation_object.save
        rescue ActiveRecord::QueryCanceled => e # rubocop:disable Database/RescueQueryCanceled -- retry with smaller batches
          # Feature flag is disabled, don't rescue, re-raise the exception
          raise e unless Feature.enabled?(:import_rescue_query_canceled, importable)

          # Check if we've exceeded the maximum number of exceptions to rescue for this relation_object (Ex. Issue)
          raise e if @exceptions_rescued >= MAX_EXCEPTION_RESCUE_COUNT

          @exceptions_rescued += 1

          track_exception(batch, e, relation_name, retry_count)
          process_with_smaller_batch_size(relation_name, batch, retry_count, e)
        end

        def save_valid_records(relation_name, valid_records)
          relation_object.public_send(relation_name) << valid_records
        end

        def save_potentially_invalid_records(relation_name, invalid_records)
          # Attempt to save some of the invalid subrelations, as they might be valid after all.
          # For example, a merge request `Approval` validates presence of merge_request_id.
          # It is not present at a time of calling `#valid?` above, since it's indeed missing.
          # However, when saving such subrelation against already persisted merge request
          # such validation won't fail (e.g. `merge_request.approvals << Approval.new(user_id: 1)`),
          # as we're operating on a merge request that has `id` present.
          invalid_records.each do |invalid_record|
            relation_object.public_send(relation_name) << invalid_record

            invalid_subrelations << invalid_record unless invalid_record.persisted?
          end
        end

        # Handles database timeouts by retrying with smaller batch sizes.
        #
        # When a batch processing operation times out (ActiveRecord::QueryCanceled),
        # this method reduces the batch size by BATCH_SIZE_REDUCTION_FACTOR and retries
        # with smaller batches until reaching MAX_RETRY_COUNT.
        #
        # @example Handling a timeout with a batch of 100 records
        #   # Initial batch of 100 causes timeout (retry_count = 0)
        #   # - New batch size = ceiling(100/4) = 25
        #   # - Creates 4 smaller batches of 25 each
        #   # - Retry count incremented to 1
        def process_with_smaller_batch_size(relation_name, batch, retry_count, exception)
          unless retry_count < MAX_RETRY_COUNT
            handle_max_retries_exceeded(batch, exception)
            return
          end

          new_retry_count = retry_count + 1

          new_batch_size = (batch.size / BATCH_SIZE_REDUCTION_FACTOR.to_f).ceil

          batch.each_slice(new_batch_size) do |smaller_batch|
            save_batch_with_retry(relation_name, smaller_batch, new_retry_count)
          end
        end

        def handle_max_retries_exceeded(batch, exception)
          batch.each do |record|
            @failed_subrelations << { record: record, exception: exception }
          end
        end

        def track_exception(batch, exception, relation_name, retry_count)
          Gitlab::ErrorTracking.track_exception(
            exception,
            relation_name: relation_name,
            relation_key: relation_key,
            batch_size: batch.size,
            retry_count: retry_count,
            exceptions_rescued: @exceptions_rescued
          )
        end

        def move_subrelations
          strong_memoize(:collection_subrelations) do
            relation_definition.each_key.each_with_object({}) do |definition, collection_subrelations|
              subrelation = relation_object.public_send(definition)
              association = relation_object.class.reflect_on_association(definition)

              next unless association&.collection?

              collection_subrelations[definition] = subrelation.records

              subrelation.clear
            end
          end
        end
        # rubocop:enable GitlabSecurity/PublicSend
      end
    end
  end
end
