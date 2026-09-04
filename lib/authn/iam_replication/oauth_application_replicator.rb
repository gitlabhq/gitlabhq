# frozen_string_literal: true

# Delivers Authn::OauthApplication outbox rows to IAM. Shared by the immediate
# write (Outboxable) and DrainWorker, so both send identical requests.

module Authn
  module IamReplication
    class OauthApplicationReplicator
      def initialize(client: ::Authn::IamService::GrpcClient.new)
        @client = client
      end

      # Returns :delivered, or :skipped if the record is gone. Raises on transport
      # failure; callers decide what to record.
      def deliver(outbox_event)
        case outbox_event.event_type
        when 'upsert'
          application = ::Authn::OauthApplication.find_by_id(outbox_event.entity_id)

          # Absent means the record was removed after this row was written
          return :skipped unless application

          # IAM has no update RPC; delete-then-create is a temporary workaround.
          # Tracked in https://gitlab.com/gitlab-org/gitlab/-/work_items/616947
          delete_upstream(application.uid)
          client.create_oauth_application(**upsert_attributes(application))
          :delivered
        when 'delete'
          client.delete_oauth_application(client_id: outbox_event.payload.symbolize_keys.fetch(:uid))
          :delivered
        else
          raise ArgumentError, "unhandled event_type: #{outbox_event.event_type}"
        end
      end

      private

      attr_reader :client

      def upsert_attributes(application)
        {
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
        }
      end

      # A first upsert has nothing upstream to replace, so a missing client is not a failure.
      def delete_upstream(uid)
        client.delete_oauth_application(client_id: uid)
      rescue ::Authn::IamService::GrpcClient::RequestError => error
        raise unless error.reason == :not_found
      end

      # Mirrors auth_helper#auth_app_owner_text
      # Temporary: removed once IAM owns the owner label, see
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/623571
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
    end
  end
end
