# GitLab Prometheus

>**Notes:**
- Prometheus and the various exporters listed in this page are bundled in the
  Omnibus GitLab package. Check each exporter's documentation for the timeline
  they got added. For installations from source you will have to install them
  yourself. Over subsequent releases additional GitLab metrics will be captured.
- Prometheus services are on by default with GitLab 9.0.
- Prometheus and its exporters do not authenticate users, and will be available
  to anyone who can access them.

[Prometheus] is a powerful time-series monitoring service, providing a flexible
platform for monitoring GitLab and other software products.
GitLab provides out of the box monitoring with Prometheus, providing easy
access to high quality time-series monitoring of GitLab services.

## Overview

Prometheus works by periodically connecting to data sources and collecting their
performance metrics via the [various exporters](#prometheus-exporters). To view
and work with the monitoring data, you can either
[connect directly to Prometheus](#viewing-performance-metrics) or utilize a
dashboard tool like [Grafana].

## Configuring Prometheus

>**Note:**
For installations from source you'll have to install and configure it yourself.

Prometheus and it's exporters are on by default, starting with GitLab 9.0.
Prometheus will run as the `gitlab-prometheus` user and listen on
`http://localhost:9090`. Each exporter will be automatically be set up as a
monitoring target for Prometheus, unless individually disabled.

To disable Prometheus and all of its exporters, as well as any added in the future:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `false`:

    ```ruby
    prometheus_monitoring['enable'] = false
    ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

## Changing the port Prometheus listens on

>**Note:**
The following change was added in [GitLab Omnibus 8.17][1261]. Although possible,
it's not recommended to change the default address and port Prometheus listens
on as this might affect or conflict with other services running on the GitLab
server. Proceed at your own risk.

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

## Viewing performance metrics

You can visit `http://localhost:9090` for the dashboard that Prometheus offers by default.

>**Note:**
If SSL has been enabled on your GitLab instance, you may not be able to access
Prometheus on the same browser as GitLab due to [HSTS][hsts]. We plan to
[provide access via GitLab][multi-user-prometheus], but in the interim there are
some workarounds: using a separate browser for Prometheus, resetting HSTS, or
having [Nginx proxy it][nginx-custom-config].

The performance data collected by Prometheus can be viewed directly in the
Prometheus console or through a compatible dashboard tool.
The Prometheus interface provides a [flexible query language][prom-query] to work
with the collected data where you can visualize their output.
For a more fully featured dashboard, Grafana can be used and has
[official support for Prometheus][prom-grafana].

Sample Prometheus queries:

- **% Memory used:** `(1 - ((node_memory_MemFree + node_memory_Cached) / node_memory_MemTotal)) * 100`
- **% CPU load:** `1 - rate(node_cpu{mode="idle"}[5m])`
- **Data transmitted:** `irate(node_network_transmit_bytes[5m])`
- **Data received:** `irate(node_network_receive_bytes[5m])`

## Configuring Prometheus to monitor Kubernetes

> Introduced in GitLab 9.0.
> Pod monitoring introduced in GitLab 9.4.

If your GitLab server is running within Kubernetes, Prometheus will collect metrics from the Nodes and [annotated Pods](https://prometheus.io/docs/operating/configuration/#<kubernetes_sd_config>) in the cluster, including performance data on each container. This is particularly helpful if your CI/CD environments run in the same cluster, as you can use the [Prometheus project integration][] to monitor them.

To disable the monitoring of Kubernetes:

1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line and set it to `false`:

    ```ruby
    prometheus['monitor_kubernetes'] = false
    ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

## GitLab Prometheus metrics

> Introduced as an experimental feature in GitLab 9.3.

GitLab monitors its own internal service metrics, and makes them available at the `/-/metrics` endpoint. Unlike other exporters, this endpoint requires authentication as it is available on the same URL and port as user traffic.

[➔ Read more about the GitLab Metrics.](gitlab_metrics.md)

## Prometheus exporters

There are a number of libraries and servers which help in exporting existing
metrics from third-party systems as Prometheus metrics. This is useful for cases
where it is not feasible to instrument a given system with Prometheus metrics
directly (for example, HAProxy or Linux system stats). You can read more in the
[Prometheus exporters and integrations upstream documentation][prom-exporters].

While you can use any exporter you like with your GitLab installation, the
following ones documented here are bundled in the Omnibus GitLab packages
making it easy to configure and use.

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

### GitLab monitor exporter

The GitLab monitor exporter allows you to measure various GitLab metrics, pulled from Redis and the database.

[➔ Read more about the GitLab monitor exporter.](gitlab_monitor_exporter.md)

[grafana]: https://grafana.net
[hsts]: https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
[multi-user-prometheus]: https://gitlab.com/gitlab-org/multi-user-prometheus
[nginx-custom-config]: https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-nginx-settings-into-the-gitlab-server-block
[prometheus]: https://prometheus.io
[prom-exporters]: https://prometheus.io/docs/instrumenting/exporters/
[prom-query]: https://prometheus.io/docs/querying/basics
[prom-grafana]: https://prometheus.io/docs/visualization/grafana/
[scrape-config]: https://prometheus.io/docs/operating/configuration/#%3Cscrape_config%3E
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
[1261]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1261
[prometheus integration]: ../../../user/project/integrations/prometheus.md
[prometheus-cadvisor-metrics]: https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md
