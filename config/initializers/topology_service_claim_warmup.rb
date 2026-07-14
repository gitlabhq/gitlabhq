# frozen_string_literal: true

# Pre-warm the Topology Service claim channel so the first claim handled by each
# worker does not pay a cold TCP + mTLS handshake on the deadline-bound claim RPC.
#
# This runs once per worker process via on_worker_start (after fork for clustered
# Puma, immediately for Sidekiq / single Puma), which is required because gRPC
# channels are not fork-safe and must be created in the worker process.
# Skip in test environment: on_worker_start yields immediately in non-clustered processes
# (Spring server, single Puma), so the warmup would create a gRPC channel in the Spring
# server process before it forks to run specs. gRPC channels cannot cross a fork on macOS.
if Gitlab.config.cell.enabled && !Rails.env.test?
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    Gitlab::TopologyServiceClient::ClaimService.instance.warmup!
  rescue StandardError => e
    # Best-effort: a failed warmup only means the connection is established lazily
    # on the first real claim, so it must never block worker startup.
    Gitlab::ErrorTracking.track_exception(e, feature_category: :cell)
  end
end
