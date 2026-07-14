# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class ClaimService < BaseService
      include Singleton

      # Claim RPCs run under a tight per-call deadline (Cells::TransactionRecord::TIMEOUT_IN_SECONDS),
      # so re-establishing the connection mid-claim risks blowing the deadline on a cold TCP + mTLS
      # handshake. At low request rates the edge may close an idle connection between claims, so we
      # keep this long-lived channel warm with keepalive pings.
      #
      # Choosing the interval is a trade-off: too long and the edge still closes the idle connection
      # between claims; too short and the peer can treat the pings as abusive, answer with
      # GOAWAY "too_many_pings", and drop the connection. 30s is a conventional gRPC keepalive
      # interval that managed HTTP/2 front ends (such as the Cloud Run/GFE edge that terminates this
      # connection) accept, so we do not need the edge's exact threshold. An interval that is too
      # aggressive is observable and self-correcting: it surfaces as "too_many_pings" GOAWAYs and
      # reconnect churn in the claim client metrics, and the channel re-establishes on the next call,
      # so the value can be tuned from real signal. For how peers decide a ping is too frequent
      # (grpc-go's server defaults, as background):
      # https://github.com/grpc/grpc/blob/6da86f12fdea143e2bda42b5cd87c87665ee77d0/doc/keepalive.md
      # and grpc-go v1.78.0 handlePing:
      # https://github.com/grpc/grpc-go/blob/v1.78.0/internal/transport/http2_server.go#L919-L949
      KEEPALIVE_TIME_MS = 30_000          # send a keepalive PING after 30s of inactivity
      KEEPALIVE_TIMEOUT_MS = 10_000       # treat the connection as dead if a PING is unacked for 10s
      CLIENT_IDLE_TIMEOUT_MS = 3_600_000  # keep an otherwise idle channel connected for up to 1h

      # Generous deadline for the boot-time warmup. The cold handshake happens off the request path
      # here, so this is intentionally looser than the per-claim deadline.
      WARMUP_TIMEOUT_IN_SECONDS = 5

      def begin_update(create_records: [], destroy_records: [], deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
          create_records: create_records,
          destroy_records: destroy_records,
          cell_id: cell_id
        )

        client.begin_update(request, deadline: deadline)
      end

      def commit_update(uuid, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
          cell_id: cell_id
        )
        client.commit_update(request, deadline: deadline)
      end

      def rollback_update(uuid, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
          cell_id: cell_id
        )
        client.rollback_update(request, deadline: deadline)
      end

      def list_leases(cursor: nil, limit: nil, created_after: nil, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::ListLeasesRequest.new(
          next: cursor,
          limit: limit,
          cell_id: cell_id
        )
        # When set, the Topology Service only returns leases with created_at >= created_after,
        # letting it seek past the tombstone backlog instead of scanning the whole range.
        if created_after
          time = created_after.to_time
          request.created_after = Google::Protobuf::Timestamp.new(seconds: time.to_i, nanos: time.nsec)
        end

        client.list_leases(request, deadline: deadline)
      end

      def list_records(source_type: nil, bucket_types: nil, source_id_gt: nil, source_id_lte: nil, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::ListRecordsRequest.new(
          source_type: source_type,
          bucket_types: bucket_types,
          source_id_gt: source_id_gt,
          source_id_lte: source_id_lte,
          cell_id: cell_id
        )

        client.list_records(request, deadline: deadline)
      end

      # Establishes the channel's TCP + mTLS connection ahead of the first claim so that the handshake
      # is not paid on a deadline-bound claim RPC. Uses ListLeases (read-only, and not counted by the
      # concurrency limiter) purely to force the connection. Best-effort: callers must rescue, because a
      # failure only means the connection is established lazily on first use.
      # A future created_after keeps this on the cheap indexed-seek path instead of the unbounded scan
      # that seeks past the whole deleted-row tombstone backlog, and guarantees zero rows are returned
      # (we discard the result anyway) since no lease can have a created_at in the future.
      # @return [void]
      def warmup!
        list_leases(
          limit: 1, created_after: 1.hour.from_now,
          deadline: GRPC::Core::TimeConsts.from_relative_time(WARMUP_TIMEOUT_IN_SECONDS))
        nil
      end

      private

      def channel_args
        super.merge(
          'grpc.keepalive_time_ms' => KEEPALIVE_TIME_MS,
          'grpc.keepalive_timeout_ms' => KEEPALIVE_TIMEOUT_MS,
          'grpc.keepalive_permit_without_calls' => 1,
          'grpc.client_idle_timeout_ms' => CLIENT_IDLE_TIMEOUT_MS
        )
      end

      def service_class
        Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub
      end
    end
  end
end
