# GitLab Prometheus

>**Notes:**
- Prometheus and the node exporter are bundled in the Omnibus GitLab package
  since GitLab 8.16. For installations from source you will have to install
  them yourself. Over subsequent releases additional GitLab metrics will be
  captured.
- Prometheus services are off by default but will be on starting with GitLab 9.0.

[Prometheus] is a powerful time-series monitoring service, providing a flexible
platform for monitoring GitLab and other software products.
GitLab provides out of the box monitoring with Prometheus, providing easy
access to high quality time-series monitoring of GitLab services.

## Overview

Prometheus works by periodically connecting to data sources and collecting their
performance metrics. To view and work with the monitoring data, you can either
connect directly to Prometheus or utilize a dashboard tool like [Grafana].

## Configuring Prometheus

>**Note:**
Available since Omnibus GitLab 8.16. For installations from source you'll
have to install and configure it yourself.

To enable Prometheus:

1. Edit `/etc/gitlab/gitlab.rb`
1. Find and uncomment the following line, making sure it's set to `true`:

    ```ruby
    prometheus['enable'] = true
    ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

By default, Prometheus will run as the `gitlab-prometheus` user and listen on
TCP port `9090` under localhost. If the [node exporter](#node-exporter) service
has been enabled, it will automatically be set up as a monitoring target for
Prometheus.

## Viewing Performance Metrics

After you have [enabled Prometheus](#configuring-prometheus), you can visit
`<your_domain_name>:9090` for the dashboard that Prometheus offers by default.

The performance data collected by Prometheus can be viewed directly in the
Prometheus console or through a compatible dashboard tool.
The Prometheus interface provides a [flexible query language][prom-query] to work
with the collected data where you can visualize their output.
For a more fully featured dashboard, Grafana can be used and has
[official support for Prometheus][prom-grafana].

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

>**Note:**
Available since Omnibus GitLab 8.16. For installations from source you'll
have to install and configure it yourself.

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
the node exporter. You can visit `<your_domain_name>:9100/metrics` for a real
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
