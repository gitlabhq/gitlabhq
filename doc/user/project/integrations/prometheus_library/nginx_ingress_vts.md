---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Monitoring NGINX Ingress Controller with VTS metrics **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/13438) in GitLab 9.5.

NOTE:
[NGINX Ingress version 0.16](nginx_ingress.md) and above have built-in Prometheus metrics, which are different than the VTS based metrics.

GitLab has support for automatically detecting and monitoring the Kubernetes NGINX Ingress controller. This is provided by leveraging the included VTS Prometheus metrics exporter in [version 0.9.0](https://github.com/kubernetes/ingress-nginx/blob/master/Changelog.md#09-beta1) through [0.15.x](https://github.com/kubernetes/ingress-nginx/blob/master/Changelog.md#0150).

## Requirements

[Prometheus integration](../prometheus.md) must be active.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | `sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) by (status_code)` |
| Latency (ms) | `avg(nginx_upstream_response_msecs_avg{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"})` |
| HTTP Error Rate (%) | `sum(rate(nginx_upstream_responses_total{status_code="5xx", upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) / sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) * 100` |

## Configuring NGINX Ingress monitoring

Version 0.9.0 and above of [NGINX Ingress](https://github.com/kubernetes/ingress-nginx) has built-in support for exporting Prometheus metrics. To enable, a ConfigMap setting must be passed: `enable-vts-status: "true"`. Once enabled, a Prometheus metrics endpoint begins running on port 10254.

Next, the Ingress needs to be annotated for Prometheus monitoring. Two new annotations need to be added:

- `prometheus.io/scrape: "true"`
- `prometheus.io/port: "10254"`

Managing these settings depends on how NGINX Ingress has been deployed. If you have deployed via the [official Helm chart](https://github.com/helm/charts/tree/master/stable/nginx-ingress), metrics can be enabled with `controller.stats.enabled` along with the required annotations. Alternatively it is possible edit the NGINX Ingress YAML directly in the [Kubernetes dashboard](https://github.com/kubernetes/dashboard).

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment, GitLab needs a method to detect which labels are associated. To do this, GitLab searches for metrics with appropriate labels. In this case, the `upstream` label must be of the form `<KUBE_NAMESPACE>-<CI_ENVIRONMENT_SLUG>-*`.

If you have used [Auto Deploy](../../../../topics/autodevops/stages.md#auto-deploy) to deploy your app, this format is used automatically and metrics are detected with no action on your part.
