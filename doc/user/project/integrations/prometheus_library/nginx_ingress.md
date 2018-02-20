# Monitoring NGINX Ingress Controller

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13438) in GitLab 9.5

GitLab has support for automatically detecting and monitoring the Kubernetes NGINX ingress controller. This is provided by leveraging the built in Prometheus metrics included in [version 0.9.0](https://github.com/kubernetes/ingress/blob/master/controllers/nginx/Changelog.md#09-beta1) and above of the ingress.

## Requirements

[Prometheus integration](../prometheus/index.md) must be active.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) by (status_code) |
| Latency (ms) | avg(nginx_upstream_response_msecs_avg{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}) |
| HTTP Error Rate (HTTP Errors / sec) | sum(rate(nginx_upstream_responses_total{status_code="5xx", upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) |

## Configuring NGINX ingress monitoring

If you have deployed NGINX Ingress using GitLab's [Kubernetes cluster integration](../../clusters/index.md#installing-applications), it will [automatically be monitored](#about-managed-nginx-ingress-deployments) by Prometheus.

For other deployments, there is [some configuration](#manually-setting-up-nginx-ingress-for-prometheus-monitoring) required depending on your installation:
* NGINX Ingress should be version 0.9.0 or above, with metrics enabled
* NGINX Ingress should be annotated for Prometheus monitoring
* Prometheus should be configured to monitor annotated pods

### About managed NGINX Ingress deployments

NGINX Ingress is deployed into the `gitlab-managed-apps` namespace, using the [official Helm chart](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress). NGINX Ingress will be [externally reachable via the Load Balancer's IP](https://docs.gitlab.com/ce/user/project/clusters/index.html#getting-the-external-ip-address).

NGINX is configured for Prometheus monitoring, by setting:
* `enable-vts-status: "true"`, to export Prometheus metrics
* `prometheus.io/scrape: "true"`, to enable automatic discovery
* `prometheus.io/port: "10254"`, to specify the metrics port

When used in conjunction with the GitLab deployed Prometheus service, response metrics will be automatically collected.

### Manually setting up NGINX Ingress for Prometheus monitoring

Version 0.9.0 and above of [NGINX ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx) have built-in support for exporting Prometheus metrics. To enable, a ConfigMap setting must be passed: `enable-vts-status: "true"`. Once enabled, a Prometheus metrics endpoint will start running on port 10254.

Next, the ingress needs to be annotated for Prometheus monitoring. Two new annotations need to be added:

* `prometheus.io/scrape: "true"`
* `prometheus.io/port: "10254"`

Managing these settings depends on how NGINX ingress has been deployed. If you have deployed via the [official Helm chart](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress), metrics can be enabled with `controller.stats.enabled` along with the required annotations. Alternatively it is possible edit the NGINX ingress YML directly in the [Kubernetes dashboard](https://github.com/kubernetes/dashboard).

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment, GitLab needs a method to detect which labels are associated. To do this, GitLab will search for metrics with appropriate labels. In this case, the `upstream` label must be of the form `<KUBE_NAMESPACE>-<CI_ENVIRONMENT_SLUG>-*`.

If you have used [Auto Deploy](https://docs.gitlab.com/ee/ci/autodeploy/index.html) to deploy your app, this format will be used automatically and metrics will be detected with no action on your part.
