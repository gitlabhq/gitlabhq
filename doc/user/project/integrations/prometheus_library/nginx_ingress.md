# Monitoring NGINX Ingress Controller

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13438) in GitLab 9.5

GitLab has support for automatically detecting and monitoring the Kubernetes NGINX ingress controller. This is provided by leveraging the built in Prometheus metrics included in [version 0.9.0](https://github.com/kubernetes/ingress/blob/master/controllers/nginx/Changelog.md#09-beta1) of the ingress.

## Requirements

The [Prometheus service](../prometheus/index.md) must be enabled.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) by (status_code) |
| Latency (ms) | avg(nginx_upstream_response_msecs_avg{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}) |
| HTTP Error Rate (HTTP Errors / sec) | sum(rate(nginx_upstream_responses_total{status_code="5xx", upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) |

## Configuring NGINX ingress monitoring

If you have deployed with the [gitlab-omnibus](https://docs.gitlab.com/ee/install/kubernetes/gitlab_omnibus.md) Helm chart, and your application is running in the same cluster, no further action is required. The ingress metrics will be automatically enabled and annotated for Prometheus monitoring. Simply ensure Prometheus monitoring is [enabled for your project](../prometheus.md), which is on by default.

For other deployments, there is some configuration required depending on your installation:
* NGINX Ingress should be version 0.9.0 or above
* NGINX Ingress should be annotated for Prometheus monitoring
* Prometheus should be configured to monitor annotated pods

### Setting up NGINX Ingress for Prometheus monitoring

Version 0.9.0 and above of [NGINX ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx) have built-in support for exporting Prometheus metrics. To enable, a ConfigMap setting must be passed: `enable-vts-status: "true"`. Once enabled, a Prometheus metrics endpoint will start running on port 10254.

With metric data now available, Prometheus needs to be configured to collect it. The easiest way to do this is to leverage Prometheus' [built-in Kubernetes service discovery](https://prometheus.io/docs/operating/configuration/#kubernetes_sd_config), which automatically detects a variety of Kubernetes components and makes them available for monitoring. Since NGINX ingress metrics are exposed per pod, a scrape job for Kubernetes pods is required. A sample pod scraping configuration [is available](https://github.com/prometheus/prometheus/blob/master/documentation/examples/prometheus-kubernetes.yml#L248). This configuration will detect pods and enable collection of metrics **only if** they have been specifically annotated for monitoring.

Depending on how NGINX ingress was deployed, typically a DaemonSet or Deployment, edit the corresponding YML spec. Two new annotations need to be added:
* `prometheus.io/scrape: "true"`
* `prometheus.io/port: "10254"`

Prometheus should now be collecting NGINX ingress metrics. To validate view the Prometheus Targets, available under `Status > Targets` on the Prometheus dashboard. New entries for NGINX should be listed in the kubernetes pod monitoring job, `kubernetes-pods`.

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment, GitLab needs a method to detect which labels are associated. To do this, GitLab will search for metrics with appropriate labels. In this case, the `upstream` label must be of the form `<KUBE_NAMESPACE>-<CI_ENVIRONMENT_SLUG>-*`.

If you have used [Auto Deploy](https://docs.gitlab.com/ee/ci/autodeploy/index.html) to deploy your app, this format will be used automatically and metrics will be detected with no action on your part.
