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
        include EachBatch
        include Gitlab::Loggable

        class_attribute :iam_outbox_entity_type

        after_create :record_iam_outbox_upsert
        after_update :record_iam_outbox_upsert
        after_destroy :record_iam_outbox_delete
      end

      class_methods do
        def iam_replicable(entity_type:)
          unless ::Authn::IamOutbox::ALLOWED_ENTITY_TYPES.include?(entity_type)
            raise ArgumentError, "unknown entity_type: #{entity_type.inspect}"
          end

          self.iam_outbox_entity_type = entity_type
        end

        # update_all bypasses the callbacks above (e.g. an organization transfer), so the moved
        # records are captured here. An empty payload suffices: the drain re-reads Rails.
        def record_iam_outbox_upserts(relation)
          return unless IamReplication.enabled?

          relation.each_batch do |batch|
            now = Time.current
            rows = batch.pluck(:id, :organization_id).map do |record_id, organization_id| # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by each_batch
              {
                entity_type: iam_outbox_entity_type,
                entity_id: record_id,
                organization_id: organization_id,
                event_type: ::Authn::IamOutbox.event_types[:upsert],
                payload: {},
                created_at: now,
                updated_at: now
              }
            end
            result = ::Authn::IamOutbox.insert_all!(rows, returning: [:entity_id])

            enqueue_drains_after_commit(result.rows.flatten, :upsert)
          end
        end

        # update_all bypasses callbacks, so we defer scheduling until the outermost
        # transaction commits, ensuring rolled-back transfers enqueue nothing.
        def enqueue_drains_after_commit(ids, event_type)
          event_type = event_type.to_s
          drain_args = ids.map { |id| [iam_outbox_entity_type, id, event_type] }

          ::ActiveRecord.after_all_transactions_commit do
            # rubocop:disable Scalability/BulkPerformWithContext -- Jobs inherit caller context; entity IDs provide traceability.
            ::Authn::IamReplication::DrainWorker.bulk_perform_in(
              ::Authn::IamReplication::DrainWorker::SCHEDULE_DELAY, drain_args
            )
            # rubocop:enable Scalability/BulkPerformWithContext
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

        outbox_event = ::Authn::IamOutbox.create!(
          entity_type: iam_outbox_entity_type,
          entity_id: id,
          organization_id: organization_id,
          event_type: event_type,
          payload: payload
        )

        run_after_commit do
          schedule_iam_outbox_drain(event_type)
          attempt_direct_iam_delivery(outbox_event)
        end
      end

      def schedule_iam_outbox_drain(event_type)
        ::Authn::IamReplication::DrainWorker.perform_in(
          ::Authn::IamReplication::DrainWorker::SCHEDULE_DELAY,
          iam_outbox_entity_type, id, event_type.to_s
        )
      end

      # Best-effort (Layer 2): failures are expected here; the outbox row lets DrainWorker retry.
      def attempt_direct_iam_delivery(outbox_event)
        return unless ::Authn::IamAuthService.enabled?

        ::Authn::IamReplication::OauthApplicationReplicator.new.deliver(outbox_event)
        outbox_event.update_columns(l0_delivered_at: Time.current, updated_at: Time.current)
      rescue StandardError => error
        ::Gitlab::AuthLogger.warn(
          build_structured_payload_labkit(
            message: 'IAM immediate write failed',
            layer: 2,
            entity_type: iam_outbox_entity_type,
            entity_id: id,
            event_type: outbox_event.event_type,
            error_type: ::Authn::IamService::GrpcClient.error_label(error)
          )
        )
      end
    end
  end
end
