---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web exporter (dedicated metrics server)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Improve reliability and performance of your GitLab monitoring by collecting metrics
separately from your main application server. A dedicated metrics server isolates
monitoring traffic from user requests, preventing metrics collection from impacting
application performance.

For medium to large installations, this separation can provide more consistent data
collection during peak usage times and can reduce the risk of missing critical metrics
during high load periods.

## How GitLab metrics collection works

When monitoring GitLab with Prometheus, GitLab runs various collectors that
sample the application for data related to usage, load and performance. GitLab can then make
this data available to a Prometheus scraper by running one or more Prometheus exporters.
A Prometheus exporter is an HTTP server that serializes metric data into a format the
Prometheus scraper understands.

{{< alert type="note" >}}

This page is about web application metrics.
To export background job metrics, learn how to [configure the Sidekiq metrics server](../../sidekiq/_index.md#configure-the-sidekiq-metrics-server).

{{< /alert >}}

We provide two mechanisms by which web application metrics can be exported:

- Through the main Rails application. This means the application server we use,
  Puma, makes metric data available through its own `/-/metrics` endpoint. This is the default,
  and is described in GitLab Metrics. You should use this default
  for small GitLab installations where the amount of metrics collected is small.
- Through a dedicated metrics server. Enabling this server causes Puma to launch an
  additional process whose sole responsibility is to serve metrics. This approach leads
  to better fault isolation and performance for very large GitLab installations, but
  comes with additional memory use. We recommend this approach for medium to large
  GitLab installations that seek high performance and availability.

Both the dedicated server and the Rails `/-/metrics` endpoint serve the same data, so
they are functionally equivalent and differ merely in their performance characteristics.

To enable the dedicated server:

1. [Enable Prometheus](_index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb` to add (or find and uncomment) the following lines. Make sure
   `puma['exporter_enabled']` is set to `true`:

   ```ruby
   puma['exporter_enabled'] = true
   puma['exporter_address'] = "127.0.0.1"
   puma['exporter_port'] = 8083
   ```

1. Configure the Prometheus scraper:
   - If you are using the GitLab-bundled Prometheus, make sure that its [`scrape_config` points to `localhost:8083/metrics`](_index.md#adding-custom-scrape-configurations).
   - If you are using an external Prometheus server, configure that [external server to scrape the new endpoint](_index.md#using-an-external-prometheus-server).
1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

Metrics can now be served and scraped from `localhost:8083/metrics`.

## Enable HTTPS

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364771) in GitLab 15.2.

{{< /history >}}

To serve metrics via HTTPS instead of HTTP, enable TLS in the exporter settings:

1. Edit `/etc/gitlab/gitlab.rb` to add (or find and uncomment) the following lines:

   ```ruby
   puma['exporter_tls_enabled'] = true
   puma['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   puma['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

When TLS is enabled, the same `port` and `address` is used as described previously.
The metrics server cannot serve both HTTP and HTTPS at the same time.

## Related topics

- [GitLab Docker installation](../../../install/docker/_index.md)
- [Monitoring GitLab with Prometheus](_index.md)
- [GitLab Metrics](_index.md#gitlab-metrics)
- [Puma operations](../../operations/puma.md)

## Troubleshooting

### Docker container runs out of space

When running GitLab in Docker, your container might run out of space. This can happen if you enable certain features which increase your space consumption, for example Web Exporter.

To work around this issue, [update your `shm-size`](../../../install/docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container).
