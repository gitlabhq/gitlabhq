---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web exporter (dedicated metrics server)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When [monitoring GitLab with Prometheus](_index.md), GitLab runs various collectors that
sample the application for data related to usage, load and performance. GitLab can then make
this data available to a Prometheus scraper by running one or more Prometheus exporters.
A Prometheus exporter is an HTTP server that serializes metric data into a format the
Prometheus scraper understands.

NOTE:
This page is about web application metrics.
To export background job metrics, learn how to [configure the Sidekiq metrics server](../../sidekiq/_index.md#configure-the-sidekiq-metrics-server).

We provide two mechanisms by which web application metrics can be exported:

- Through the main Rails application. This means [Puma](../../operations/puma.md), the application server we use,
  makes metric data available via its own `/-/metrics` endpoint. This is the default,
  and is described in [GitLab Metrics](_index.md#gitlab-metrics). We recommend this
  default for small GitLab installations where the amount of metrics collected is small.
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

1. When using the GitLab-bundled Prometheus, make sure that its `scrape_config` is pointing
   to `localhost:8083/metrics`. Refer to the [Adding custom scrape configurations](_index.md#adding-custom-scrape-configurations) page
   for how to configure scraper targets. For external Prometheus setup, refer to
   [Using an external Prometheus server](_index.md#using-an-external-prometheus-server) instead.
1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

Metrics can now be served and scraped from `localhost:8083/metrics`.

## Enable HTTPS

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364771) in GitLab 15.2.

To serve metrics via HTTPS instead of HTTP, enable TLS in the exporter settings:

1. Edit `/etc/gitlab/gitlab.rb` to add (or find and uncomment) the following lines:

   ```ruby
   puma['exporter_tls_enabled'] = true
   puma['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   puma['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

When TLS is enabled, the same `port` and `address` is used as described above.
The metrics server cannot serve both HTTP and HTTPS at the same time.

## Troubleshooting

### Docker container runs out of space

When running [GitLab in Docker](../../../install/docker/_index.md), your container might run out of space. This can happen if you enable certain features which increase your space consumption, for example Web Exporter.

To work around this issue, [update your `shm-size`](../../../install/docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container).
