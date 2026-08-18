# frozen_string_literal: true

# Writes an iam_outbox row for every mutation of the including model, inside the same
# transaction as the mutation (a rolled-back mutation leaves no outbox row). The drain
# kick is deferred to after_commit.
# Including models declare their type with `iam_replicable` and implement `#iam_outbox_delete_payload`.

module Authn
  module IamReplication
    module Outboxable
      extend ActiveSupport::Concern

      included do
        include AfterCommitQueue

        class_attribute :iam_outbox_entity_type

        after_create :record_iam_outbox_upsert
        after_update :record_iam_outbox_upsert
        after_destroy :record_iam_outbox_delete
      end

      class_methods do
        def iam_replicable(entity_type:)
          raise ArgumentError, 'entity_type must be a non-empty string' if entity_type.blank?

          self.iam_outbox_entity_type = entity_type
        end

        # update_all bypasses the callbacks above (e.g. an organization transfer), so the moved
        # records are captured here. An empty payload suffices: the drain re-reads Rails.
        def record_iam_outbox_upserts(relation)
          return unless IamReplication.enabled?

          relation.each_batch do |batch|
            now = Time.current
            rows = batch.select(:id, :organization_id).map do |record|
              {
                entity_type: iam_outbox_entity_type,
                entity_id: record.id,
                organization_id: record.organization_id,
                event_type: ::Authn::IamOutbox.event_types[:upsert],
                payload: {},
                created_at: now,
                updated_at: now
              }
            end

            ::Authn::IamOutbox.insert_all!(rows)
          end
        end
      end

      # Empty because the drain re-reads Rails for the current state on upsert.
      def iam_outbox_upsert_payload
        {}
      end

      # The record is gone by drain time, so the includer must supply whatever identifies the
      # deletion upstream. Must exclude secrets and tokens.
      def iam_outbox_delete_payload
        raise Gitlab::AbstractMethodError
      end

      private

      def record_iam_outbox_upsert
        write_iam_outbox_event(:upsert, iam_outbox_upsert_payload)
      end

      def record_iam_outbox_delete
        write_iam_outbox_event(:delete, iam_outbox_delete_payload)
      end

      def write_iam_outbox_event(event_type, payload)
        return unless IamReplication.enabled?

        ::Authn::IamOutbox.create!(
          entity_type: iam_outbox_entity_type,
          entity_id: id,
          organization_id: organization_id,
          event_type: event_type,
          payload: payload
        )

        run_after_commit { schedule_iam_outbox_drain(event_type) }
      end

      # Enqueued once the drain worker lands (see gitlab-org/gitlab#602678):
      #   DrainWorker.perform_in(delay, iam_outbox_entity_type, id, event_type.to_s)
      def schedule_iam_outbox_drain(event_type); end
    end
  end
end
