---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Monitoring Kubernetes (deprecated) **(FREE)**

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346541) in GitLab 14.7.

WARNING:
This feature is in its end-of-life process. It is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/346541)
in GitLab 14.7, and is planned for removal in GitLab 16.0.

GitLab has support for automatically detecting and monitoring Kubernetes metrics.

## Prerequisite

The [Prometheus](../prometheus.md) and [Kubernetes](../../../infrastructure/clusters/index.md)
integration services must be enabled.

## Metrics supported

- Average Memory Usage (MB):

  ```prometheus
  avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024
  ```

- Average CPU Utilization (%):

  ```prometheus
  avg(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}[15m])) by (job)) without (job) / count(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-([^c].*|c([^a]|a([^n]|n([^a]|a([^r]|r[^y])))).*|)-(.*)",namespace="%{kube_namespace}"}[15m])) by (pod_name))
  ```

## Configuring Prometheus to monitor for Kubernetes metrics

Prometheus needs to be deployed into the cluster and configured properly to gather Kubernetes metrics. GitLab supports two methods for doing so:

- GitLab [integrates with Kubernetes](../../clusters/index.md), and can [query a Prometheus in a connected cluster](../../../clusters/integrations.md#prometheus-cluster-integration). The in-cluster Prometheus can be configured to automatically collect application metrics from your cluster.
- To configure your own Prometheus server, you can follow the [Prometheus documentation](https://prometheus.io/docs/introduction/overview/).

## Specifying the Environment

To isolate and only display relevant CPU and Memory metrics for a given environment, GitLab needs a method to detect which containers it is running. Because these metrics are tracked at the container level, traditional Kubernetes labels are not available.

Instead, the [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) or [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) name should begin with [CI_ENVIRONMENT_SLUG](../../../../ci/variables/index.md#predefined-cicd-variables). It can be followed by a `-` and additional content if desired. For example, a deployment name of `review-homepage-5620p5` would match the `review/homepage` environment.

## Displaying Canary metrics **(PREMIUM)**

GitLab also gathers Kubernetes metrics for [canary deployments](../../canary_deployments.md), allowing easy comparison between the current deployed version and the canary.

These metrics expect the [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) or [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) name to begin with `$CI_ENVIRONMENT_SLUG-canary`, to isolate the canary metrics.

### Canary metrics supported

- Average Memory Usage (MB)

  ```prometheus
  avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-canary-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job) / count(avg(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-canary-(.*)",namespace="%{kube_namespace}"}) without (job)) /1024/1024
  ```

- Average CPU Utilization (%)

  ```prometheus
  avg(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-canary-(.*)",namespace="%{kube_namespace}"}[15m])) by (job)) without (job) / count(sum(rate(container_cpu_usage_seconds_total{container_name!="POD",pod_name=~"^%{ci_environment_slug}-canary-(.*)",namespace="%{kube_namespace}"}[15m])) by (pod_name))
  ```
