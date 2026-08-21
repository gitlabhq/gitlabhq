# frozen_string_literal: true

# Drains pending iam_outbox rows for a single entity to the IAM service.
#
# Scheduled with a ~1-minute delay so replica reads settle, and deduplicated
# on its args so bursts of same-entity mutations collapse to a single run.
#
# Only L0 delivery is implemented; l2_* columns are reserved for a follow-up.

module Authn
  module IamReplication
    class DrainWorker
      include ApplicationWorker

      SCHEDULE_DELAY = 1.minute
      TARGET = :l0

      idempotent!
      deduplicate :until_executing, including_scheduled: true
      data_consistency :sticky
      feature_category :system_access
      urgency :low
      worker_has_external_dependencies!
      loggable_arguments 0, 1, 2
      defer_on_database_health_signal :gitlab_main, [:iam_outbox], 1.minute

      def perform(entity_type, entity_id, event_type)
        return unless ::Authn::IamReplication.enabled? && ::Authn::IamAuthService.enabled?

        raise ArgumentError, "unknown event_type: #{event_type}" unless
          ::Authn::IamOutbox.event_types.key?(event_type)

        ids = ::Authn::IamOutbox.l0_undelivered_ids(entity_type, entity_id, event_type)
        return if ids.empty?

        rows = ::Authn::IamOutbox.id_in(ids)
        deliver(rows, rows.last)
      end

      private

      # All pending rows for one entity and event type converge to a single delivery: an upsert
      # re-reads the current Rails state, a delete is keyed on the uid the row carries.
      def deliver(rows, latest)
        result =
          case latest.event_type
          when 'upsert' then deliver_upsert(latest.entity_id)
          when 'delete' then deliver_delete(latest.payload['uid'])
          else raise ArgumentError, "unhandled event_type: #{latest.event_type}"
          end

        rows.update_all(l0_delivered_at: Time.current, updated_at: Time.current)
        log(latest, result: result, attempts: latest.l0_attempts)
      rescue StandardError => error
        record_failure(rows, latest, error)
        raise
      end

      # When more entity types are added, extract a per-entity replicator and dispatch by entity_type.
      def deliver_upsert(entity_id)
        application = ::Authn::OauthApplication.find_by_id(entity_id)

        # Absent means the record was removed after this upsert was enqueued
        return :skipped unless application

        # IAM has no update RPC; delete-then-create is a temporary workaround.
        # Tracked in https://gitlab.com/gitlab-org/gitlab/-/work_items/616947
        delete_upstream(application.uid)
        client.create_oauth_application(
          client_id: application.uid,
          client_secret: application.secret,
          client_name: application.name,
          redirect_uris: application.redirect_uri.split,
          scopes: application.scopes.to_a,
          public: !application.confidential?,
          trusted: application.trusted?,
          owner: owner_label(application),
          grant_types: grant_types(application),
          response_types: %w[code],
          created_at: timestamp(application.created_at),
          updated_at: timestamp(application.updated_at)
        )
        :delivered
      end

      # Mirrors auth_helper#auth_app_owner_text
      def owner_label(application)
        return 'An anonymous service' if application.dynamic?
        return 'An administrator' unless application.owner

        application.owner.name
      end

      # Grant types are per-application and intentionally decoupled from Doorkeeper.config,
      # since Doorkeeper's flows are instance-wide while IAM needs per-application types.
      # Omitting `device_code` as not implemented yet in IAM.
      def grant_types(application)
        types = %w[authorization_code refresh_token]
        types << 'client_credentials' if application.confidential?
        types
      end

      def timestamp(time)
        ::Google::Protobuf::Timestamp.new(seconds: time.to_i)
      end

      def deliver_delete(uid)
        client.delete_oauth_application(client_id: uid)
        :delivered
      end

      # A first upsert has nothing upstream to replace, so a missing client is not a failure.
      def delete_upstream(uid)
        client.delete_oauth_application(client_id: uid)
      rescue ::Authn::IamService::GrpcClient::RequestError => error
        raise unless error.reason == :not_found
      end

      def record_failure(rows, latest, error)
        rows.update_all(l0_last_error: failure_reason(error), updated_at: Time.current)
        rows.update_counters(l0_attempts: 1)
        log(latest, result: :error, attempts: latest.l0_attempts + 1)
      end

      def failure_reason(error)
        return error.reason.to_s if error.is_a?(::Authn::IamService::GrpcClient::RequestError)

        error.class.name
      end

      def client
        @client ||= ::Authn::IamService::GrpcClient.new
      end

      def log(row, result:, attempts:)
        ::Gitlab::AuthLogger.info(
          build_structured_payload_labkit(
            message: 'IAM outbox row delivery',
            entity_type: row.entity_type,
            entity_id: row.entity_id,
            event_type: row.event_type,
            target: TARGET,
            attempts: attempts,
            result: result
          )
        )
      end
    end
  end
end
