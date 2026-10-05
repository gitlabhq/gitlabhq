# frozen_string_literal: true

# Sends Authn::OauthApplication rows to IAM, so every replication layer sends identical requests.

module Authn
  module IamReplication
    class OauthApplicationReplicator
      # IAM accepts only this format. Older applications can still store a PBKDF2 or
      # plaintext secret.
      SHA512_HEX_DIGEST = /\A[0-9a-f]{128}\z/

      def self.reconciliation_scope
        ::Authn::OauthApplication.preload(:organization, :owner) # rubocop:disable CodeReuse/ActiveRecord -- scope owned by the Layer 4 reconciliation
      end

      def initialize(client: nil, timeout: nil)
        @client = client || ::Authn::IamService::GrpcClient.new(timeout: timeout)
      end

      # Returns :delivered, :skipped if the record is gone, or :unsupported_secret_digest.
      # Raises on transport failure; callers decide what to record.
      def deliver(outbox_event)
        case outbox_event.event_type
        when 'upsert'
          application = ::Authn::OauthApplication.find_by_id(outbox_event.entity_id)

          # Absent means the record was removed after this row was written
          return :skipped unless application

          upsert(application)
        when 'delete'
          delete_upstream(outbox_event.payload.symbolize_keys.fetch(:uid))
          :delivered
        else
          raise ArgumentError, "unhandled event_type: #{outbox_event.event_type}"
        end
      end

      def upsert(application)
        return :unsupported_secret_digest unless SHA512_HEX_DIGEST.match?(application.secret)

        client.upsert_oauth_application(**upsert_attributes(application))
        :delivered
      end

      private

      attr_reader :client

      # NOT_FOUND means the client is already gone, which is the desired end
      # state, so it counts as delivered. Layer 2 usually deletes it first.
      def delete_upstream(uid)
        client.delete_oauth_application(client_id: uid)
      rescue ::Authn::IamService::GrpcClient::RequestError => error
        raise unless error.reason == :not_found
      end

      def upsert_attributes(application)
        {
          client_id: application.uid,
          # application.secret is already a SHA-512 digest (Doorkeeper's
          # Sha512Hash strategy), satisfying IAM's hashed_client_secret
          # contract as-is; IAM stores it verbatim and never sees plaintext.
          hashed_client_secret: application.secret,
          redirect_uris: application.redirect_uri.split,
          grant_types: grant_types(application),
          response_types: %w[code],
          scopes: application.scopes.to_a,
          public: !application.confidential?,
          client_name: application.name,
          owner: owner_label(application),
          trusted: application.trusted?,
          created_at: timestamp(application.created_at),
          updated_at: timestamp(application.updated_at),
          dynamic: application.dynamic?,
          organization_id: application.organization.uuid,
          owning_cell_id: Gitlab.config.cell.id.to_i
        }
      end

      # Mirrors auth_helper#auth_app_owner_text
      def owner_label(application)
        return if application.dynamic?
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
