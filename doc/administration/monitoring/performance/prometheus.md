# GitLab Prometheus

>**Notes:**
- Prometheus and Node Exporter have been bundled in the Omnibus GitLab package
  since GitLab 8.16. For installations from source you will have to install
  them yourself. Over subsequent releases additional GitLab metrics will be
  captured.
- Prometheus and its exporters are off by default but will be on starting with GitLab 9.0.
- Prometheus and its exporters do not authenticate users, and will be available to anyone who can access them.

[Prometheus] is a powerful time-series monitoring service, providing a flexible
platform for monitoring GitLab and other software products.
GitLab provides out of the box monitoring with Prometheus, providing easy
access to high quality time-series monitoring of GitLab services.

## Overview

Prometheus works by periodically connecting to data sources and collecting their
performance metrics. To view and work with the monitoring data, you can either
connect directly to Prometheus or utilize a dashboard tool like [Grafana].

## Configuring Prometheus

To enable Prometheus:

1. Edit `/etc/gitlab/gitlab.rb`
1. Find and uncomment the following line, making sure it's set to `true`:

    ```ruby
    prometheus['enable'] = true
    ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

By default, Prometheus will run as the `gitlab-prometheus` user and listen on
`http://localhost:9090`. If the [node exporter](#node-exporter) service
has been enabled, it will automatically be set up as a monitoring target for
Prometheus.

## Viewing Performance Metrics

After you have [enabled Prometheus](#configuring-prometheus), you can visit
`http://localhost:9090` for the dashboard that Prometheus offers by default.

>**Note:**
If SSL has been enabled, you may not be able to access Prometheus on the same browser as GitLab due to [HSTS][hsts]. We plan to [provide access via GitLab][multi-user-prometheus], but in the interim there are some workarounds: using a separate browser for Prometheus, resetting HSTS, or having [nginx proxy it][nginx-custom-config].

The performance data collected by Prometheus can be viewed directly in the
Prometheus console or through a compatible dashboard tool.
The Prometheus interface provides a [flexible query language][prom-query] to work
with the collected data where you can visualize their output.
For a more fully featured dashboard, Grafana can be used and has
[official support for Prometheus][prom-grafana].

Sample Prometheus Queries:
* % Memory Used: `(1 - ((node_memory_MemFree + node_memory_Cached) / node_memory_MemTotal)) * 100`
* % CPU Load: `1 - rate(node_cpu{mode="idle"}[5m])`
* Data Transmitted: `irate(node_network_transmit_bytes[5m])`
* Data Received: `irate(node_network_receive_bytes[5m])`

## Prometheus exporters

There are a number of libraries and servers which help in exporting existing
metrics from third-party systems as Prometheus metrics. This is useful for cases
where it is not feasible to instrument a given system with Prometheus metrics
directly (for example, HAProxy or Linux system stats). You can read more in the
[Prometheus exporters and integrations documentation][prom-exporters].

While you can use any exporter you like with your GitLab installation, the
following ones documented here are bundled in the Omnibus GitLab packages
making it easy to configure and use.

### Node exporter

The [node exporter] allows you to measure various machine resources such as
memory, disk and CPU utilization.

To enable the node exporter:

1. [Enable Prometheus](#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Find and uncomment the following line, making sure it's set to `true`:

    ```ruby
    node_exporter['enable'] = true
    ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

Prometheus it will now automatically begin collecting performance data from
the node exporter. You can visit `http://localhost:9100/metrics` for a real
time representation of the metrics that are collected. Refresh the page and
you will see the data change.

[grafana]: https://grafana.net
[node exporter]: https://github.com/prometheus/node_exporter
[prometheus]: https://prometheus.io
[prom-query]: https://prometheus.io/docs/querying/basics
[prom-grafana]: https://prometheus.io/docs/visualization/grafana/
[scrape-config]: https://prometheus.io/docs/operating/configuration/#%3Cscrape_config%3E
[prom-exporters]: https://prometheus.io/docs/instrumenting/exporters/
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
[hsts]: https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security
[multi-user-prometheus]: https://gitlab.com/gitlab-org/multi-user-prometheus
[nginx-custom-config]: https://docs.gitlab.com/omnibus/settings/configuration.html#inserting-custom-nginx-settings-into-the-gitlab-server-block