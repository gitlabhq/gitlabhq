# Monitoring HA Proxy
> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12621) in GitLab 9.4

GitLab has support for automatically detecting and monitoring HA Proxy. This is provided by leveraging the [HA Proxy Exporter](https://github.com/hnlq715/nginx-vts-exporter), which translates HA Proxy statistics into a Prometheus readable form.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(rate(haproxy_frontend_http_requests_total{%{environment_filter}}[2m])) |
| HTTP Error Rate (%) | sum(rate(haproxy_frontend_http_requests_total{code="5xx",%{environment_filter}}[2m])) / sum(rate(haproxy_frontend_http_requests_total{%{environment_filter}}[2m])) |

## Configuring Prometheus to monitor for HA Proxy metrics

To get started with NGINX monitoring, you should install and configure the [HA Proxy exporter](https://github.com/prometheus/haproxy_exporter) which parses these statistics and translates them into a Prometheus monitoring endpoint.

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab will [look for an `environment` label](metrics.md#identifying-environments).
