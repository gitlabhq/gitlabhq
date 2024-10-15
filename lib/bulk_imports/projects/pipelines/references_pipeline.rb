# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ReferencesPipeline
        include Pipeline

        BATCH_SIZE = 100
        DELAY = 1.second

        def extract(context)
          @tracker_id = context.tracker.id
          @counter = 0

          enqueue_ref_workers_for_issues_and_issue_notes
          enqueue_ref_workers_for_merge_requests_and_merge_request_notes

          nil
        end

        attr_reader :tracker_id

        private

        def enqueue_ref_workers_for_issues_and_issue_notes
          portable.issues.select(:id).each_batch(of: BATCH_SIZE, column: :iid) do |batch|
            BulkImports::TransformReferencesWorker.perform_in(delay, batch.map(&:id), Issue.to_s, tracker_id)

            batch.each do |issue|
              issue.notes.select(:id, :noteable_id, :noteable_type).each_batch(of: BATCH_SIZE) do |notes_batch|
                BulkImports::TransformReferencesWorker.perform_in(delay, notes_batch.map(&:id), Note.to_s, tracker_id)
              end
            end
          end
        end

        def enqueue_ref_workers_for_merge_requests_and_merge_request_notes
          portable.merge_requests.select(:id).each_batch(of: BATCH_SIZE, column: :iid) do |batch|
            BulkImports::TransformReferencesWorker.perform_in(delay, batch.map(&:id), MergeRequest.to_s, tracker_id)

            batch.each do |merge_request|
              merge_request.notes.select(:id).each_batch(of: BATCH_SIZE) do |notes_batch|
                BulkImports::TransformReferencesWorker.perform_in(delay, notes_batch.map(&:id), Note.to_s, tracker_id)
              end
            end
          end
        end

        def delay
          @counter += 1
          @counter * DELAY
        end
      end
    end
  end
end
