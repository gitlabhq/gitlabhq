# Monitoring NGINX Ingress Controller
> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13438) in GitLab 9.5

GitLab has support for automatically detecting and monitoring the Kubernetes NGINX ingress controller. This is provided by leveraging the built in Prometheus metrics included in [version 0.9.0](https://github.com/kubernetes/ingress/blob/master/controllers/nginx/Changelog.md#09-beta1) of the ingress.

## Metrics supported

| Name | Query |
| ---- | ----- |
| Throughput (req/sec) | sum(rate(nginx_upstream_requests_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) |
| Latency (ms) | avg(nginx_upstream_response_msecs_avg{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}) |
| HTTP Error Rate (HTTP Errors / sec) | sum(rate(nginx_upstream_responses_total{status_code="5xx", upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[2m])) |

## Configuring Prometheus to monitor for NGINX ingress metrics

The easiest way to get started is to use at least version 0.9.0 of [NGINX ingress](https://github.com/kubernetes/ingress/tree/master/controllers/nginx). If you are using NGINX as your Kubernetes ingress, there is [direct support](https://github.com/kubernetes/ingress/pull/423) for enabling Prometheus monitoring in the 0.9.0 release.

If you have deployed with the [gitlab-omnibus](https://docs.gitlab.com/ee/install/kubernetes/gitlab_omnibus.md) Helm chart, these metrics will be automatically enabled and annotated for Prometheus monitoring.

## Specifying the Environment label

In order to isolate and only display relevant metrics for a given environment
however, GitLab needs a method to detect which labels are associated. To do this, GitLab will search metrics with appropriate labels. In this case, the `upstream` label must be of the form `<Kubernetes Namespace>-<CI_ENVIRONMENT_SLUG>-*`.

If you have used [Auto Deploy](https://docs.gitlab.com/ee/ci/autodeploy/index.html) to deploy your app, this format will be used automatically and metrics will be detected with no action on your part.
