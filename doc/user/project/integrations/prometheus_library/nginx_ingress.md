# Monitoring NGINX Ingress Controller

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22133) in GitLab 11.7.

NOTE: **Note:** NGINX Ingress versions prior to 0.16.0 offer an included [VTS Prometheus metrics exporter](nginx_ingress_vts.md), which exports metrics different than the built-in metrics.

GitLab has support for automatically detecting and monitoring the Kubernetes NGINX Ingress controller. This is provided by leveraging the built-in Prometheus metrics included with Kubernetes NGINX Ingress Controller [version 0.16.0](https://github.com/kubernetes/ingress-nginx/blob/master/Changelog.md#0160) onward.

## Requirements

[Prometheus integration](../prometheus.md) must be active.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | `sum(label_replace(rate(nginx_ingress_controller_requests{namespace="%{kube_namespace}",ingress=~".*%{ci_environment_slug}.*"}[2m]), "status_code", "${1}xx", "status", "(.)..")) by (status_code)` |
| Latency (ms) | `sum(rate(nginx_ingress_controller_ingress_upstream_latency_seconds_sum{namespace="%{kube_namespace}",ingress=~".*%{ci_environment_slug}.*"}[2m])) / sum(rate(nginx_ingress_controller_ingress_upstream_latency_seconds_count{namespace="%{kube_namespace}",ingress=~".*%{ci_environment_slug}.*"}[2m])) * 1000` |
| HTTP Error Rate (%) | `sum(rate(nginx_ingress_controller_requests{status=~"5.*",namespace="%{kube_namespace}",ingress=~".*%{ci_environment_slug}.*"}[2m])) / sum(rate(nginx_ingress_controller_requests{namespace="%{kube_namespace}",ingress=~".*%{ci_environment_slug}.*"}[2m])) * 100` |

## Configuring NGINX Ingress monitoring

If you have deployed NGINX Ingress using GitLab's [Kubernetes cluster integration](../../clusters/index.md#installing-applications), it will [automatically be monitored](#about-managed-nginx-ingress-deployments) by Prometheus.

For other deployments, there is [some configuration](#manually-setting-up-nginx-ingress-for-prometheus-monitoring) required depending on your installation:

- NGINX Ingress should be version 0.16.0 or above, with metrics enabled.
- NGINX Ingress should be annotated for Prometheus monitoring.
- Prometheus should be configured to monitor annotated pods.

### About managed NGINX Ingress deployments

NGINX Ingress is deployed into the `gitlab-managed-apps` namespace, using the [official Helm chart](https://github.com/helm/charts/tree/master/stable/nginx-ingress). NGINX Ingress will be [externally reachable via the Load Balancer's Endpoint](../../../clusters/applications.md#ingress).

NGINX is configured for Prometheus monitoring, by setting:

- `enable-vts-status: "true"`, to export Prometheus metrics.
- `prometheus.io/scrape: "true"`, to enable automatic discovery.
- `prometheus.io/port: "10254"`, to specify the metrics port.

When used in conjunction with the GitLab deployed Prometheus service, response metrics will be automatically collected.

### Manually setting up NGINX Ingress for Prometheus monitoring

Version 0.9.0 and above of [NGINX Ingress](https://github.com/kubernetes/ingress-nginx) have built-in support for exporting Prometheus metrics. To enable, a ConfigMap setting must be passed: `enable-vts-status: "true"`. Once enabled, a Prometheus metrics endpoint will start running on port 10254.

Next, the Ingress needs to be annotated for Prometheus monitoring. Two new annotations need to be added:

- `prometheus.io/scrape: "true"`
- `prometheus.io/port: "10254"`

Managing these settings depends on how NGINX Ingress has been deployed. If you have deployed via the [official Helm chart](https://github.com/helm/charts/tree/master/stable/nginx-ingress), metrics can be enabled with `controller.stats.enabled` along with the required annotations. Alternatively it is possible to edit the NGINX Ingress YML directly in the [Kubernetes dashboard](https://github.com/kubernetes/dashboard).

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment, GitLab needs a method to detect which labels are associated. To do this, GitLab will search for metrics with appropriate labels. In this case, the `ingress` label must `<CI_ENVIRONMENT_SLUG>`.

If you have used [Auto Deploy](../../../../topics/autodevops/index.md#auto-deploy) to deploy your app, this format will be used automatically and metrics will be detected with no action on your part.
