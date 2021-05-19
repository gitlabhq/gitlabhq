# frozen_string_literal: true

# -----------------------------------------------------------------------
# This file is used by the GDK to generate a default config/puma.rb file
# Note that `/home/git` will be substituted for the actual GDK root
# directory when this file is generated
# -----------------------------------------------------------------------

# Load "path" as a rackup file.
#
# The default is "config.ru".
#
rackup 'config.ru'
pidfile '/home/git/gitlab/tmp/pids/puma.pid'
state_path '/home/git/gitlab/tmp/pids/puma.state'

## Uncomment the lines if you would like to write puma stdout & stderr streams
## to a different location than rails logs.
## When using GitLab Development Kit, by default, these logs will be consumed
## by runit and can be accessed using `gdk tail rails-web`
# stdout_redirect '/home/git/gitlab/log/puma.stdout.log',
#  '/home/git/gitlab/log/puma.stderr.log',
#  true

# Configure "min" to be the minimum number of threads to use to answer
# requests and "max" the maximum.
#
# The default is "0, 16".
#
threads 1, 4

# By default, workers accept all requests and queue them to pass to handlers.
# When false, workers accept the number of simultaneous requests configured.
#
# Queueing requests generally improves performance, but can cause deadlocks if
# the app is waiting on a request to itself. See https://github.com/puma/puma/issues/612
#
# When set to false this may require a reverse proxy to handle slow clients and
# queue requests before they reach puma. This is due to disabling HTTP keepalive
queue_requests false

# Bind the server to "url". "tcp://", "unix://" and "ssl://" are the only
# accepted protocols.
bind 'unix:///home/git/gitlab.socket'

workers 2

require_relative "/home/git/gitlab/lib/gitlab/cluster/lifecycle_events"

on_restart do
  # Signal application hooks that we're about to restart
  Gitlab::Cluster::LifecycleEvents.do_before_master_restart
end

before_fork do
  # Signal to the puma killer
  Gitlab::Cluster::PumaWorkerKillerInitializer.start @config.options unless ENV['DISABLE_PUMA_WORKER_KILLER']

  # Signal application hooks that we're about to fork
  Gitlab::Cluster::LifecycleEvents.do_before_fork
end

Gitlab::Cluster::LifecycleEvents.set_puma_options @config.options
on_worker_boot do
  # Signal application hooks of worker start
  Gitlab::Cluster::LifecycleEvents.do_worker_start
end

# Preload the application before starting the workers; this conflicts with
# phased restart feature. (off by default)

preload_app!

tag 'gitlab-puma-worker'

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. Default
# value is 60 seconds.
#
worker_timeout 60

# https://github.com/puma/puma/blob/master/5.0-Upgrade.md#lower-latency-better-throughput
wait_for_less_busy_worker ENV.fetch('PUMA_WAIT_FOR_LESS_BUSY_WORKER', 0.001).to_f

# https://github.com/puma/puma/blob/master/5.0-Upgrade.md#nakayoshi_fork
nakayoshi_fork unless ENV['DISABLE_PUMA_NAKAYOSHI_FORK'] == 'true'

# Use json formatter
require_relative "/home/git/gitlab/lib/gitlab/puma_logging/json_formatter"

json_formatter = Gitlab::PumaLogging::JSONFormatter.new
log_formatter do |str|
  json_formatter.call(str)
end
