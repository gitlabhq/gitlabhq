# Monitoring Kubernetes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8935) in GitLab 9.0

GitLab has support for automatically detecting and monitoring Kubernetes metrics.

## Requirements

The [Prometheus](../prometheus.md) and [Kubernetes](../kubernetes.md)
integration services must be enabled.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Average Memory Usage (MB) | avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024 |
| Average CPU Utilization (%) | avg(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}[15m])) by (job)) without (job) / count(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}[15m])) by (pod_name)) |

## Configuring Prometheus to monitor for Kubernetes metrics

Prometheus needs to be deployed into the cluster and configured properly in order to gather Kubernetes metrics. GitLab supports two methods for doing so:

- GitLab [integrates with Kubernetes](../../clusters/index.md), and can [deploy Prometheus into a connected cluster](../prometheus.html#managed-prometheus-on-kubernetes). It is automatically configured to collect Kubernetes metrics.
- To configure your own Prometheus server, you can follow the [Prometheus documentation](https://prometheus.io/docs/introduction/overview/).

## Specifying the Environment

In order to isolate and only display relevant CPU and Memory metrics for a given environment, GitLab needs a method to detect which containers it is running. Because these metrics are tracked at the container level, traditional Kubernetes labels are not available.

Instead, the [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) or [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) name should begin with [CI_ENVIRONMENT_SLUG](../../../../ci/variables/README.md#predefined-variables-environment-variables). It can be followed by a `-` and additional content if desired. For example, a deployment name of `review-homepage-5620p5` would match the `review/homepage` environment.
