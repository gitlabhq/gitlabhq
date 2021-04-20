---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring NGINX **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12621) in GitLab 9.4

GitLab has support for automatically detecting and monitoring NGINX. This is provided by leveraging the [NGINX VTS exporter](https://github.com/hnlq715/nginx-vts-exporter), which translates [VTS statistics](https://github.com/vozlt/nginx-module-vts) into a Prometheus readable form.

## Requirements

The [Prometheus service](../prometheus.md) must be enabled.

## Metrics supported

NGINX server metrics are detected, which tracks the pages and content directly served by NGINX.

[`environment_filter`](../../../../operations/metrics/dashboards/variables.md#environment_filter) is one of the predefined variables that metrics dashboards support.

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | `sum(rate(nginx_server_requests{server_zone!="*", server_zone!="_", %{environment_filter}}[2m])) by (code)` |
| Latency (ms) | `avg(nginx_server_requestMsec{%{environment_filter}})` |
| HTTP Error Rate (HTTP Errors / sec) | `sum(rate(nginx_server_requests{code="5xx", %{environment_filter}}[2m]))` |
| HTTP Error (%)| `sum(rate(nginx_server_requests{code=~"5.*", host="*", %{environment_filter}}[2m])) / sum(rate(nginx_server_requests{code="total", host="*", %{environment_filter}}[2m])) * 100` |

## Configuring Prometheus to monitor for NGINX metrics

To get started with NGINX monitoring, you should first enable the [VTS statistics](https://github.com/vozlt/nginx-module-vts) module for your NGINX server. This captures and displays statistics in an HTML readable form. Next, you should install and configure the [NGINX VTS exporter](https://github.com/hnlq715/nginx-vts-exporter) which parses these statistics and translates them into a Prometheus monitoring endpoint.

If you are using NGINX as your Kubernetes Ingress, GitLab [automatically detects](nginx_ingress.md) the metrics once enabled in 0.9.0 and later releases.

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab [looks for an `environment` label](index.md#identifying-environments).
