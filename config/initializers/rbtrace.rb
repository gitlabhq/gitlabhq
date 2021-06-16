# frozen_string_literal: true

if ENV['ENABLE_RBTRACE']
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    # We need to require `rbtrace` in a context of a worker process.
    # See https://github.com/tmm1/rbtrace/issues/56#issuecomment-648683596.
    require 'rbtrace'
  end
end
