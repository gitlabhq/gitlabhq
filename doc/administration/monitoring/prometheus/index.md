---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring GitLab with Prometheus **(FREE SELF)**

[Prometheus](https://prometheus.io) is a powerful time-series monitoring service, providing a flexible
platform for monitoring GitLab and other software products.
GitLab provides out-of-the-box monitoring with Prometheus, providing easy
access to high quality time-series monitoring of GitLab services.

> **Notes:**
>
> - Prometheus and the various exporters listed in this page are bundled in the
>   Omnibus GitLab package. Check each exporter's documentation for the timeline
>   they got added. For installations from source you must install them
>   yourself. Over subsequent releases additional GitLab metrics are captured.
> - Prometheus services are on by default with GitLab 9.0.
> - Prometheus and its exporters don't authenticate users, and are available
>  to anyone who can access them.

## Overview

Prometheus works by periodically connecting to data sources and collecting their
performance metrics through the [various exporters](#bundled-software-metrics). To view
and work with the monitoring data, you can either
[connect directly to Prometheus](#viewing-performance-metrics) or use a
dashboard tool like [Grafana](https://grafana.com).

## Configuring Prometheus

For installations from source, you must install and configure it yourself.

Prometheus and its exporters are on by default, starting with GitLab 9.0.
Prometheus runs as the `gitlab-prometheus` user and listen on
`http://localhost:9090`. By default, Prometheus is only accessible from the GitLab server itself.
Each exporter is automatically set up as a
monitoring target for Prometheus, unless individually disabled.

To disable Prometheus and all of its exporters, as well as any added in the future:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `false`:

   ```ruby
   prometheus_monitoring['enable'] = false
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect.

### Changing the port and address Prometheus listens on

WARNING:
The following change was added in [Omnibus GitLab 8.17](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/1261). Although possible,
it's not recommended to change the port Prometheus listens
on, as this might affect or conflict with other services running on the GitLab
server. Proceed at your own risk.

To access Prometheus from outside the GitLab server, set an FQDN or IP in
`prometheus['listen_address']`. To change the address/port that Prometheus
listens on:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line:

   ```ruby
   prometheus['listen_address'] = 'localhost:9090'
   ```

   Replace `localhost:9090` with the address or port you want Prometheus to
   listen on. If you would like to allow access to Prometheus to hosts other
   than `localhost`, leave out the host, or use `0.0.0.0` to allow public access:

   ```ruby
   prometheus['listen_address'] = ':9090'
   # or
   prometheus['listen_address'] = '0.0.0.0:9090'
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect

### Adding custom scrape configurations

You can configure additional scrape targets for the Omnibus GitLab-bundled
Prometheus by editing `prometheus['scrape_configs']` in `/etc/gitlab/gitlab.rb`
using the [Prometheus scrape target configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E)
syntax.

Here is an example configuration to scrape `http://1.1.1.1:8060/probe?param_a=test&param_b=additional_test`:

```ruby
prometheus['scrape_configs'] = [
  {
    'job_name': 'custom-scrape',
    'metrics_path': '/probe',
    'params' => {
      'param_a' => ['test'],
      'param_b' => ['additional_test']
    },
    'static_configs' => [
      'targets' => ['1.1.1.1:8060'],
    ],
  },
]
```

### Standalone Prometheus using Omnibus GitLab

The Omnibus GitLab package can be used to configure a standalone Monitoring node running Prometheus and [Grafana](../performance/grafana_configuration.md).

The steps below are the minimum necessary to configure a Monitoring node running Prometheus and Grafana with Omnibus GitLab:

1. SSH into the Monitoring node.
1. [Install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page, but
   do not follow the remaining steps.
1. Make sure to collect the IP addresses or DNS records of the Consul server nodes, for the next step.
1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   roles ['monitoring_role']

   external_url 'http://gitlab.example.com'

   # Prometheus
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Grafana
   grafana['enable'] = true
   grafana['admin_password'] = 'toomanysecrets'
   grafana['disable_login_form'] = false

   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true
   consul['configuration'] = { 
      retry_join: %w(10.0.0.1 10.0.0.2 10.0.0.3), # The addresses can be IPs or FQDNs
   }

   # Nginx - For Grafana access
   nginx['enable'] = true
   ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.

The next step is to tell all the other nodes where the monitoring node is:

1. Edit `/etc/gitlab/gitlab.rb`, and add, or find and uncomment the following line:

   ```ruby
   gitlab_rails['prometheus_address'] = '10.0.0.1:9090'
   ```

   Where `10.0.0.1:9090` is the IP address and port of the Prometheus node.

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect.

After monitoring using Service Discovery is enabled with `consul['monitoring_service_discovery'] =  true`,
ensure that `prometheus['scrape_configs']` is not set in `/etc/gitlab/gitlab.rb`. Setting both
`consul['monitoring_service_discovery'] = true` and `prometheus['scrape_configs']` in `/etc/gitlab/gitlab.rb` results in errors.

### Using an external Prometheus server

WARNING:
Prometheus and most exporters don't support authentication. We don't recommend exposing them outside the local network.

A few configuration changes are required to allow GitLab to be monitored by an external Prometheus server. External servers are recommended for [GitLab deployments with multiple nodes](../../reference_architectures/index.md).

To use an external Prometheus server:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Disable the bundled Prometheus:

   ```ruby
   prometheus['enable'] = false
   ```

1. Set each bundled service's [exporter](#bundled-software-metrics) to listen on a network address, for example:

   ```ruby
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"

   # Rails nodes
   gitlab_exporter['listen_address'] = '0.0.0.0'
   gitlab_exporter['listen_port'] = '9168'

   # Sidekiq nodes
   sidekiq['listen_address'] = '0.0.0.0'

   # Redis nodes
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # PostgreSQL nodes
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   # Gitaly nodes
   gitaly['prometheus_listen_addr'] = "0.0.0.0:9236"
   ```

1. Install and set up a dedicated Prometheus instance, if necessary, using the [official installation instructions](https://prometheus.io/docs/prometheus/latest/installation/).
1. Add the Prometheus server IP address to the [monitoring IP whitelist](../ip_whitelist.md). For example:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. On **all** GitLab Rails(Puma, Sidekiq) servers, set the Prometheus server IP address and listen port. For example:

   ```ruby
   gitlab_rails['prometheus_address'] = '192.168.0.1:9090'
   ```

1. To scrape NGINX metrics, you must also configure NGINX to allow the Prometheus server
   IP. For example:

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => "192.168.0.1",
         "deny" => "all",
   }
   ```

1. [Reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) to apply the changes.
1. Edit the Prometheus server's configuration file.
1. Add each node's exporters to the Prometheus server's
   [scrape target configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E).
   For example, a sample snippet using `static_configs`:

   ```yaml
   scrape_configs:
     - job_name: nginx
       static_configs:
         - targets:
           - 1.1.1.1:8060
     - job_name: redis
       static_configs:
         - targets:
           - 1.1.1.1:9121
     - job_name: postgres
       static_configs:
         - targets:
           - 1.1.1.1:9187
     - job_name: node
       static_configs:
         - targets:
           - 1.1.1.1:9100
     - job_name: gitlab-workhorse
       static_configs:
         - targets:
           - 1.1.1.1:9229
     - job_name: gitlab-rails
       metrics_path: "/-/metrics"
       static_configs:
         - targets:
           - 1.1.1.1:8080
     - job_name: gitlab-sidekiq
       static_configs:
         - targets:
           - 1.1.1.1:8082
     - job_name: gitlab_exporter_database
       metrics_path: "/database"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitlab_exporter_sidekiq
       metrics_path: "/sidekiq"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitlab_exporter_process
       metrics_path: "/process"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitaly
       static_configs:
         - targets:
           - 1.1.1.1:9236
   ```

1. Reload the Prometheus server.

## Viewing performance metrics

You can visit `http://localhost:9090` for the dashboard that Prometheus offers by default.

If SSL has been enabled on your GitLab instance, you may not be able to access
Prometheus on the same browser as GitLab if using the same FQDN due to [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security). We plan to
[provide access via GitLab](https://gitlab.com/gitlab-org/multi-user-prometheus), but in the interim there are
some workarounds: using a separate FQDN, using server IP, using a separate browser for Prometheus, resetting HSTS, or
having [NGINX proxy it](https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-nginx-settings-into-the-gitlab-server-block).

The performance data collected by Prometheus can be viewed directly in the
Prometheus console, or through a compatible dashboard tool.
The Prometheus interface provides a [flexible query language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
to work with the collected data where you can visualize the output.
For a more fully featured dashboard, Grafana can be used and has
[official support for Prometheus](https://prometheus.io/docs/visualization/grafana/).

Sample Prometheus queries:

- **% Memory available:** `((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or ((node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes)) * 100`
- **% CPU utilization:** `1 - avg without (mode,cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- **Data transmitted:** `rate(node_network_transmit_bytes_total{device!="lo"}[5m])`
- **Data received:** `rate(node_network_receive_bytes_total{device!="lo"}[5m])`

## Prometheus as a Grafana data source

Grafana allows you to import Prometheus performance metrics as a data source,
and render the metrics as graphs and dashboards, which is helpful with visualization.

To add a Prometheus dashboard for a single server GitLab setup:

1. Create a new data source in Grafana.
1. Name your data source (such as GitLab).
1. Select `Prometheus` in the type dropdown box.
1. Add your Prometheus listen address as the URL, and set access to `Browser`.
1. Set the HTTP method to `GET`.
1. Save and test your configuration to verify that it works.

## GitLab metrics

> Introduced in GitLab 9.3.

GitLab monitors its own internal service metrics, and makes them available at the `/-/metrics` endpoint. Unlike other exporters, this endpoint requires authentication as it's available on the same URL and port as user traffic.

Read more about the [GitLab Metrics](gitlab_metrics.md).

## Bundled software metrics

Many of the GitLab dependencies bundled in Omnibus GitLab are preconfigured to
export Prometheus metrics.

### Node exporter

The node exporter allows you to measure various machine resources, such as
memory, disk, and CPU utilization.

[Read more about the node exporter](node_exporter.md).

### Redis exporter

The Redis exporter allows you to measure various Redis metrics.

[Read more about the Redis exporter](redis_exporter.md).

### PostgreSQL exporter

The PostgreSQL exporter allows you to measure various PostgreSQL metrics.

[Read more about the PostgreSQL exporter](postgres_exporter.md).

### PgBouncer exporter

The PgBouncer exporter allows you to measure various PgBouncer metrics.

[Read more about the PgBouncer exporter](pgbouncer_exporter.md).

### Registry exporter

The Registry exporter allows you to measure various Registry metrics.

[Read more about the Registry exporter](registry_exporter.md).

### GitLab exporter

The GitLab exporter allows you to measure various GitLab metrics, pulled from Redis and the database.

[Read more about the GitLab exporter](gitlab_exporter.md).

## Configuring Prometheus to monitor Kubernetes

> - Introduced in GitLab 9.0.
> - Pod monitoring introduced in GitLab 9.4.

If your GitLab server is running within Kubernetes, Prometheus collects metrics from the Nodes and [annotated Pods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) in the cluster, including performance data on each container. This is particularly helpful if your CI/CD environments run in the same cluster, as you can use the [Prometheus project integration](../../../user/project/integrations/prometheus.md) to monitor them.

To disable the monitoring of Kubernetes:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Add (or find and uncomment) the following line and set it to `false`:

   ```ruby
   prometheus['monitor_kubernetes'] = false
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect.
