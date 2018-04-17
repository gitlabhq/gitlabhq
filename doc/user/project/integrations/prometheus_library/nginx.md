# Monitoring NGINX

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12621) in GitLab 9.4

GitLab has support for automatically detecting and monitoring NGINX. This is provided by leveraging the [NGINX VTS exporter](https://github.com/hnlq715/nginx-vts-exporter), which translates [VTS statistics](https://github.com/vozlt/nginx-module-vts) into a Prometheus readable form.

## Requirements

The [Prometheus service](../prometheus.md) must be enabled.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(rate(nginx_responses_total{server_zone!="*", server_zone!="_", %{environment_filter}}[2m])) by (status_code) |
| Latency (ms) | avg(nginx_upstream_response_msecs_avg{%{environment_filter}}) |
| HTTP Error Rate (HTTP Errors / sec) | rate(nginx_responses_total{status_code="5xx", %{environment_filter}}[2m])) |

## Configuring Prometheus to monitor for NGINX metrics

To get started with NGINX monitoring, you should first enable the [VTS statistics](https://github.com/vozlt/nginx-module-vts)) module for your NGINX server. This will capture and display statistics in an HTML readable form. Next, you should install and configure the [NGINX VTS exporter](https://github.com/hnlq715/nginx-vts-exporter) which parses these statistics and translates them into a Prometheus monitoring endpoint.

If you are using NGINX as your Kubernetes ingress, there is [upcoming direct support](https://github.com/kubernetes/ingress/pull/423) for enabling Prometheus monitoring in the 0.9.0 release.

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab will [look for an `environment` label](metrics.md#identifying-environments).
