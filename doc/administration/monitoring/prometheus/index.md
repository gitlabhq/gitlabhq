# Monitoring GitLab with Prometheus

> **Notes:**
>
> - Prometheus and the various exporters listed in this page are bundled in the
>   Omnibus GitLab package. Check each exporter's documentation for the timeline
>   they got added. For installations from source you will have to install them
>   yourself. Over subsequent releases additional GitLab metrics will be captured.
> - Prometheus services are on by default with GitLab 9.0.
> - Prometheus and its exporters do not authenticate users, and will be available
>  to anyone who can access them.

[Prometheus] is a powerful time-series monitoring service, providing a flexible
platform for monitoring GitLab and other software products.
GitLab provides out of the box monitoring with Prometheus, providing easy
access to high quality time-series monitoring of GitLab services.

## Overview

Prometheus works by periodically connecting to data sources and collecting their
performance metrics via the [various exporters](#bundled-software-metrics). To view
and work with the monitoring data, you can either
[connect directly to Prometheus](#viewing-performance-metrics) or utilize a
dashboard tool like [Grafana](https://grafana.com).

## Configuring Prometheus

NOTE: **Note:**
For installations from source you'll have to install and configure it yourself.

Prometheus and its exporters are on by default, starting with GitLab 9.0.
Prometheus will run as the `gitlab-prometheus` user and listen on
`http://localhost:9090`. By default Prometheus is only accessible from the GitLab server itself.
Each exporter will be automatically set up as a
monitoring target for Prometheus, unless individually disabled.

To disable Prometheus and all of its exporters, as well as any added in the future:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `false`:

   ```ruby
   prometheus_monitoring['enable'] = false
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect.

### Changing the port and address Prometheus listens on

NOTE: **Note:**
The following change was added in [GitLab Omnibus 8.17][1261]. Although possible,
it's not recommended to change the port Prometheus listens
on as this might affect or conflict with other services running on the GitLab
server. Proceed at your own risk.

In order to access Prometheus from outside the GitLab server you will need to
set a FQDN or IP in `prometheus['listen_address']`.
To change the address/port that Prometheus listens on:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line:

   ```ruby
   prometheus['listen_address'] = 'localhost:9090'
   ```

   Replace `localhost:9090` with the address/port you want Prometheus to
   listen on. If you would like to allow access to Prometheus to hosts other
   than `localhost`, leave out the host, or use `0.0.0.0` to allow public access:

   ```ruby
   prometheus['listen_address'] = ':9090'
   # or
   prometheus['listen_address'] = '0.0.0.0:9090'
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

### Adding custom scrape configs

You can configure additional scrape targets for the GitLab Omnibus-bundled
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

### Using an external Prometheus server

NOTE: **Note:**
Prometheus and most exporters do not support authentication. We do not recommend exposing them outside the local network.

A few configuration changes are required to allow GitLab to be monitored by an external Prometheus server. External servers are recommended for highly available deployments of GitLab with multiple nodes.

To use an external Prometheus server:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Disable the bundled Prometheus:

   ```ruby
   prometheus['enable'] = false
   ```

1. Set each bundled service's [exporter](#bundled-software-metrics) to listen on a network address, for example:

   ```ruby
   gitlab_exporter['listen_address'] = '0.0.0.0'
   sidekiq['listen_address'] = '0.0.0.0'
   gitlab_exporter['listen_port'] = '9168'
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   postgres_exporter['listen_address'] = '0.0.0.0:9187'
   gitaly['prometheus_listen_addr'] = "0.0.0.0:9236"
   gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"
   ```

1. Install and set up a dedicated Prometheus instance, if necessary, using the [official installation instructions](https://prometheus.io/docs/prometheus/latest/installation/).
1. Add the Prometheus server IP address to the [monitoring IP whitelist](../ip_whitelist.html). For example:

    ```ruby
    gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
    ```

1. To scrape NGINX metrics, you'll also need to configure NGINX to allow the Prometheus server
   IP. For example:

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => "192.168.0.1",
         "deny" => "all",
   }
   ```

1. [Reconfigure GitLab][reconfigure] to apply the changes
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

>**Note:**
If SSL has been enabled on your GitLab instance, you may not be able to access
Prometheus on the same browser as GitLab if using the same FQDN due to [HSTS][hsts]. We plan to
[provide access via GitLab][multi-user-prometheus], but in the interim there are
some workarounds: using a separate FQDN, using server IP, using a separate browser for Prometheus, resetting HSTS, or
having [NGINX proxy it][nginx-custom-config].

The performance data collected by Prometheus can be viewed directly in the
Prometheus console or through a compatible dashboard tool.
The Prometheus interface provides a [flexible query language](https://prometheus.io/docs/prometheus/latest/querying/basics/)
to work with the collected data where you can visualize their output.
For a more fully featured dashboard, Grafana can be used and has
[official support for Prometheus][prom-grafana].

Sample Prometheus queries:

- **% Memory available:** `((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or ((node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes)) * 100`
- **% CPU utilization:** `1 - avg without (mode,cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- **Data transmitted:** `rate(node_network_transmit_bytes_total{device!="lo"}[5m])`
- **Data received:** `rate(node_network_receive_bytes_total{device!="lo"}[5m])`

## Prometheus as a Grafana data source

Grafana allows you to import Prometheus performance metrics as a data source
and render the metrics as graphs and dashboards which is helpful with visualisation.

To add a Prometheus dashboard for a single server GitLab setup:

1. Create a new data source in Grafana.
1. Name your data source i.e GitLab.
1. Select `Prometheus` in the type drop down.
1. Add your Prometheus listen address as the URL and set access to `Browser`.
1. Set the HTTP method to `GET`.
1. Save & Test your configuration to verify that it works.

## GitLab metrics

> Introduced in GitLab 9.3.

GitLab monitors its own internal service metrics, and makes them available at the `/-/metrics` endpoint. Unlike other exporters, this endpoint requires authentication as it is available on the same URL and port as user traffic.

[➔ Read more about the GitLab Metrics.](gitlab_metrics.md)

## Bundled software metrics

Many of the GitLab dependencies bundled in Omnibus GitLab are preconfigured to
export Prometheus metrics.

### Node exporter

The node exporter allows you to measure various machine resources such as
memory, disk and CPU utilization.

[➔ Read more about the node exporter.](node_exporter.md)

### Redis exporter

The Redis exporter allows you to measure various Redis metrics.

[➔ Read more about the Redis exporter.](redis_exporter.md)

### Postgres exporter

The Postgres exporter allows you to measure various PostgreSQL metrics.

[➔ Read more about the Postgres exporter.](postgres_exporter.md)

### PgBouncer exporter

The PgBouncer exporter allows you to measure various PgBouncer metrics.

[➔ Read more about the PgBouncer exporter.](pgbouncer_exporter.md)

### GitLab exporter

The GitLab exporter allows you to measure various GitLab metrics, pulled from Redis and the database.

[➔ Read more about the GitLab exporter.](gitlab_exporter.md)

## Configuring Prometheus to monitor Kubernetes

> Introduced in GitLab 9.0.
> Pod monitoring introduced in GitLab 9.4.

If your GitLab server is running within Kubernetes, Prometheus will collect metrics from the Nodes and [annotated Pods](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) in the cluster, including performance data on each container. This is particularly helpful if your CI/CD environments run in the same cluster, as you can use the [Prometheus project integration][prometheus integration] to monitor them.

To disable the monitoring of Kubernetes:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Add or find and uncomment the following line and set it to `false`:

   ```ruby
   prometheus['monitor_kubernetes'] = false
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect.

[hsts]: https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
[multi-user-prometheus]: https://gitlab.com/gitlab-org/multi-user-prometheus
[nginx-custom-config]: https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-nginx-settings-into-the-gitlab-server-block
[prometheus]: https://prometheus.io
[prom-grafana]: https://prometheus.io/docs/visualization/grafana/
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
[1261]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1261
[prometheus integration]: ../../../user/project/integrations/prometheus.md
