# Monitoring Kubernetes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8935) in GitLab 9.0

GitLab has support for automatically detecting and monitoring Kubernetes metrics.

## Requirements

The [Prometheus](../prometheus.md) and [Kubernetes](../kubernetes.md)
integration services must be enabled.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Average Memory Usage (MB) | (sum(avg(container_memory_usage_bytes{container_name!="POD",environment="%{ci_environment_slug}"}) without (job))) / count(avg(container_memory_usage_bytes{container_name!="POD",environment="%{ci_environment_slug}"}) without (job)) /1024/1024 |
| Average CPU Utilization (%) | sum(avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="%{ci_environment_slug}"}[2m])) without (job)) * 100 |

## Configuring Prometheus to monitor for Kubernetes node metrics

In order for Prometheus to collect Kubernetes metrics, you first must have a
Prometheus server up and running. You have two options here:

- If you have an Omnibus based GitLab installation within your Kubernetes cluster, you can leverage the bundled Prometheus server to [monitor Kubernetes](../../../../administration/monitoring/prometheus/index.md#configuring-prometheus-to-monitor-kubernetes).
- To configure your own Prometheus server, you can follow the [Prometheus documentation](https://prometheus.io/docs/introduction/overview/) or [our guide](../../../../administration/monitoring/prometheus/index.md#configuring-your-own-prometheus-server-within-kubernetes).

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab will [look for an `environment` label](metrics.md#identifying-environments).

If you are using [GitLab Auto-Deploy](../../../../ci/autodeploy/index.md) and one of the two [provided Kubernetes monitoring solutions](../prometheus.md#getting-started-with-prometheus-monitoring), the `environment` label will be automatically added.
