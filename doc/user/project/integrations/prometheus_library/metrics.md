# Prometheus Metrics library
> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8935) in GitLab 9.0

GitLab offers

## Metrics and Labels

GitLab retrieves performance data from two metrics, `container_cpu_usage_seconds_total`
and `container_memory_usage_bytes`. These metrics are collected from the
Kubernetes pods via Prometheus, and report CPU and Memory utilization of each
container or Pod running in the cluster.

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which pods are associated. To do that,
GitLab will specifically request metrics that have an `environment` tag that
matches the [$CI_ENVIRONMENT_SLUG][ci-environment-slug].

If you are using [GitLab Auto-Deploy][autodeploy] and one of the methods of
configuring Prometheus above, the `environment` will be automatically added.

## Configuring Prometheus to collect automatically collected metrics within Kubernetes

In order for Prometheus to collect Kubernetes metrics, you first must have a
Prometheus server up and running. You have two options here:

- If you installed Omnibus GitLab inside of Kubernetes, you can simply use the
  [bundled version of Prometheus][promgldocs]. In that case, follow the info in the
  [Omnibus GitLab section](#configuring-omnibus-gitlab-prometheus-to-monitor-kubernetes)
  below.
- If you are using GitLab.com or installed GitLab outside of Kubernetes, you
  will likely need to run a Prometheus server within the Kubernetes cluster.
  Once installed, the easiest way to monitor Kubernetes is to simply use
  Prometheus' support for [Kubernetes Service Discovery][prometheus-k8s-sd].
  In that case, follow the instructions on
  [configuring your own Prometheus server within Kubernetes](../prometheus.md#configuring-your-own-prometheus-server-within-kubernetes).
