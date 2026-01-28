# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module Observability
        module Events
          # It organizes the BBO events into a single place
          class Event
            def initialize(record, **attributes)
              @record = record
              @attributes = attributes
            end

            def log
              Gitlab::AppLogger.info(payload.merge(shared_payload))
            end

            def payload
              raise NotImplementedError, 'Subclasses must implement the payload method'
            end

            private

            attr_reader :record, :attributes

            # Shared payload for all records:
            # BackgroundOperation::Worker,
            # BackgroundOperation::WorkerCellLocal,
            # BackgroundOperation::Job,
            # BackgroundOperation::JobCellLocal
            def shared_payload
              partition, id = record.id

              {
                id: id,
                partition: partition,
                record_type: record.class.name,
                min_cursor: record.min_cursor,
                max_cursor: record.max_cursor,
                created_at: record.created_at,
                started_at: record.started_at,
                finished_at: record.finished_at
              }
            end
          end
        end
      end
    end
  end
end
