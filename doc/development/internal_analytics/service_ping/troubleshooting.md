---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Troubleshooting Service Ping
---

## Set up and test Service Ping locally

To set up Service Ping locally, you must:

1. [Set up local repositories](#set-up-local-repositories).
1. [Test local setup](#test-local-setup).
1. Optional. [Test Prometheus-based Service Ping](#test-prometheus-based-service-ping).

### Set up local repositories

1. Clone and start [GitLab](https://gitlab.com/gitlab-org/gitlab-development-kit).
1. Clone and start [Versions Application](https://gitlab.com/gitlab-org/gitlab-services/version.gitlab.com).
   Make sure you run `docker-compose up` to start a PostgreSQL and Redis instance.
1. Point GitLab to the Versions Application endpoint instead of the default endpoint:
   1. Open [service_ping/submit_service.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/service_ping/submit_service.rb#L5) locally and modify `STAGING_BASE_URL`.
   1. Set it to the local Versions Application URL: `http://localhost:3000`.

### Test local setup

1. Using the `gitlab` Rails console, manually trigger Service Ping:

   ```ruby
   GitlabServicePingWorker.new.perform('triggered_from_cron' => false)
   ```

1. Use the `versions` Rails console to check the Service Ping was successfully received,
   parsed, and stored in the Versions database:

   ```ruby
   UsageData.last
   ```

## Test Prometheus-based Service Ping

If the data submitted includes metrics [queried from Prometheus](../metrics/metrics_instrumentation.md#prometheus-metrics)
you want to inspect and verify, you must:

- Ensure that a Prometheus server is running locally.
- Ensure the respective GitLab components are exporting metrics to the Prometheus server.

If you do not need to test data coming from Prometheus, no further action
is necessary. Service Ping should degrade gracefully in the absence of a running Prometheus server.

Three kinds of components may export data to Prometheus, and are included in Service Ping:

- [`node_exporter`](https://github.com/prometheus/node_exporter): Exports node metrics
  from the host machine.
- [`gitlab-exporter`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter): Exports process metrics
  from various GitLab components.
- Other various GitLab services, such as Sidekiq and the Rails server, which export their own metrics.

### Test with an Omnibus container

This is the recommended approach to test Prometheus-based Service Ping.

To verify your change, build a new Omnibus image from your code branch using CI/CD, download the image,
and run a local container instance:

1. From your merge request, select the `qa` stage, then trigger the `e2e:test-on-omnibus` job. This job triggers an Omnibus
   build in a [downstream pipeline of the `omnibus-gitlab-mirror` project](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/-/pipelines).
1. In the downstream pipeline, wait for the `gitlab-docker` job to finish.
1. Open the job logs and locate the full container name including the version. It takes the following form: `registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:<VERSION>`.
1. On your local machine, make sure you are signed in to the GitLab Docker registry. You can find the instructions for this in
   [Authenticate to the GitLab container registry](../../../user/packages/container_registry/authenticate_with_container_registry.md).
1. Once signed in, download the new image by using `docker pull registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:<VERSION>`
1. For more information about working with and running Omnibus GitLab containers in Docker, refer to [GitLab Docker images](../../../install/docker/_index.md) documentation.

### Test with GitLab development toolkits

This is the less recommended approach, because it comes with a number of difficulties when emulating a real GitLab deployment.

The [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) is not set up to run a Prometheus server or `node_exporter` alongside other GitLab components. If you would
like to do so, [Monitoring the GDK with Prometheus](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/prometheus/index.md#monitoring-the-gdk-with-prometheus) is a good start.

The [GCK](https://gitlab.com/gitlab-org/gitlab-compose-kit) has limited support for testing Prometheus based Service Ping.
By default, it comes with a fully configured Prometheus service that is set up to scrape a number of components.
However, it has the following limitations:

- It does not run a `gitlab-exporter` instance, so several `process_*` metrics from services such as Gitaly may be missing.
- While it runs a `node_exporter`, `docker-compose` services emulate hosts, meaning that it usually reports itself as not associated
  with any of the other running services. That is not how node metrics are reported in a production setup, where `node_exporter`
  always runs as a process alongside other GitLab components on any given node. For Service Ping, none of the node data would therefore
  appear to be associated to any of the services running, because they all appear to be running on different hosts. To alleviate this problem, the `node_exporter` in GCK was arbitrarily "assigned" to the `web` service, meaning only for this service `node_*` metrics appears in Service Ping.

## Generate Service Ping

### Generate or get the cached Service Ping in rails console

Use the following method in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values, cached: true)
```

### Generate a fresh new Service Ping

Use the following method in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

This also refreshes the cached Service Ping displayed in the **Admin** area.

```ruby
Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
```

### Generate a new Service Ping including today's usage data

Use the following methods in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

```ruby
require_relative 'spec/support/helpers/service_ping_helpers.rb'

ServicePingHelpers.get_current_service_ping_payload

# To get a single metric's value, provide the metric's key_path like so:
ServicePingHelpers.get_current_usage_metric_value('counts.count_total_render_duo_pro_lead_page')
```

### Generate and print

Generates Service Ping data in JSON format.

```shell
gitlab-rake gitlab:usage_data:generate
```

Generates Service Ping data in YAML format:

```shell
gitlab-rake gitlab:usage_data:dump_sql_in_yaml
```

### Generate and send Service Ping

Prints the metrics saved in `conversational_development_index_metrics`.

```shell
gitlab-rake gitlab:usage_data:generate_and_send
```
