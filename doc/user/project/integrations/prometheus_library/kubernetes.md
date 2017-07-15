# Monitoring Kubernetes
> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8935) in GitLab 9.0

GitLab has support for automatically detecting and monitoring Kubernetes metrics. Kubernetes exposes Node level metrics out of the box via the built-in [Prometheus metrics support in cAdvisor](https://github.com/google/cadvisor).

## Metrics supported

| Name | Query |
| ---- | ----- |
| Average Memory Usage (MB) | (sum(container_memory_usage_bytes{container_name!="POD",%{environment_filter}}) / count(container_memory_usage_bytes{container_name!="POD",%{environment_filter}})) /1024/1024 |
| Average CPU Utilization (%) | sum(rate(container_cpu_usage_seconds_total{container_name!="POD",%{environment_filter}}[2m])) / count(container_cpu_usage_seconds_total{container_name!="POD",%{environment_filter}}) * 100 |

## Configuring Prometheus to monitor for Kubernetes node metrics

Prometheus has internal support for discovering and monitoring of Kubernetes node metrics.

If you have an Omnibus based GitLab installation within your Kubernetes cluster, you can leverage the bundled Prometheus server to [monitor Kubernetes](../../../../administration/monitoring/prometheus/index.md#configuring-prometheus-to-monitor-kubernetes).

To configure your own Prometheus server 
