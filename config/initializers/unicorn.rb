Gitlab::Unicorn::Hook.after_fork do |server, worker|
  ## TODO: `Prometheus::Client.store_worker_id(worker.id)`
  Prometheus::Client.reinitialize_on_pid_change
end
