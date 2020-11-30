---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Requirements for Auto DevOps

You can set up Auto DevOps for [Kubernetes](#auto-devops-requirements-for-kubernetes)
or [Amazon Elastic Container Service (ECS)](#auto-devops-requirements-for-amazon-ecs).
For more information about Auto DevOps, see [the main Auto DevOps page](index.md)
or the [quick start guide](quick_start_guide.md).

## Auto DevOps requirements for Kubernetes

To make full use of Auto DevOps with Kubernetes, you need:

- **Kubernetes** (for [Auto Review Apps](stages.md#auto-review-apps),
  [Auto Deploy](stages.md#auto-deploy), and [Auto Monitoring](stages.md#auto-monitoring))

  To enable deployments, you need:

  1. A [Kubernetes 1.12+ cluster](../../user/project/clusters/index.md) for your
     project. The easiest way is to create a
     [new cluster using the GitLab UI](../../user/project/clusters/add_remove_clusters.md#create-new-cluster).
     For Kubernetes 1.16+ clusters, you must perform additional configuration for
     [Auto Deploy for Kubernetes 1.16+](stages.md#kubernetes-116).
  1. NGINX Ingress. You can deploy it to your Kubernetes cluster by installing
     the [GitLab-managed app for Ingress](../../user/clusters/applications.md#ingress),
     after configuring GitLab's Kubernetes integration in the previous step.

     Alternatively, you can use the
     [`nginx-ingress`](https://github.com/helm/charts/tree/master/stable/nginx-ingress)
     Helm chart to install Ingress manually.

     NOTE: **Note:**
     If you use your own Ingress instead of the one provided by GitLab's managed
     apps, ensure you're running at least version 0.9.0 of NGINX Ingress and
     [enable Prometheus metrics](https://github.com/helm/charts/tree/master/stable/nginx-ingress#prometheus-metrics)
     for the response metrics to appear. You must also
     [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
     the NGINX Ingress deployment to be scraped by Prometheus using
     `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

- **Base domain** (for [Auto Review Apps](stages.md#auto-review-apps),
  [Auto Deploy](stages.md#auto-deploy), and [Auto Monitoring](stages.md#auto-monitoring))

  You need a domain configured with wildcard DNS, which all of your Auto DevOps
  applications use. If you're using the
  [GitLab-managed app for Ingress](../../user/clusters/applications.md#ingress),
  the URL endpoint is automatically configured for you.

  You must also [specify the Auto DevOps base domain](index.md#auto-devops-base-domain).

- **GitLab Runner** (for all stages)

  Your runner must be configured to run Docker, usually with either the
  [Docker](https://docs.gitlab.com/runner/executors/docker.html)
  or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html) executors, with
  [privileged mode enabled](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode).
  The runners don't need to be installed in the Kubernetes cluster, but the
  Kubernetes executor is easy to use and automatically autoscales.
  You can configure Docker-based runners to autoscale as well, using
  [Docker Machine](https://docs.gitlab.com/runner/install/autoscaling.html).

  If you've configured GitLab's Kubernetes integration in the first step, you
  can deploy it to your cluster by installing the
  [GitLab-managed app for GitLab Runner](../../user/clusters/applications.md#gitlab-runner).

  Runners should be registered as [shared runners](../../ci/runners/README.md#shared-runners)
  for the entire GitLab instance, or [specific runners](../../ci/runners/README.md#specific-runners)
  that are assigned to specific projects (the default if you've installed the
  GitLab Runner managed application).

- **Prometheus** (for [Auto Monitoring](stages.md#auto-monitoring))

  To enable Auto Monitoring, you need Prometheus installed either inside or
  outside your cluster, and configured to scrape your Kubernetes cluster.
  If you've configured GitLab's Kubernetes integration, you can deploy it to
  your cluster by installing the
  [GitLab-managed app for Prometheus](../../user/clusters/applications.md#prometheus).

  The [Prometheus service](../../user/project/integrations/prometheus.md)
  integration must be enabled for the project, or enabled as a
  [default service template](../../user/project/integrations/services_templates.md)
  for the entire GitLab installation.

  To get response metrics (in addition to system metrics), you must
  [configure Prometheus to monitor NGINX](../../user/project/integrations/prometheus_library/nginx_ingress.md#configuring-nginx-ingress-monitoring).

- **cert-manager** (optional, for TLS/HTTPS)

  To enable HTTPS endpoints for your application, you must install cert-manager,
  a native Kubernetes certificate management controller that helps with issuing
  certificates. Installing cert-manager on your cluster issues a
  [Let’s Encrypt](https://letsencrypt.org/) certificate and ensures the
  certificates are valid and up-to-date. If you've configured GitLab's Kubernetes
  integration, you can deploy it to your cluster by installing the
  [GitLab-managed app for cert-manager](../../user/clusters/applications.md#cert-manager).

If you don't have Kubernetes or Prometheus installed, then
[Auto Review Apps](stages.md#auto-review-apps),
[Auto Deploy](stages.md#auto-deploy), and [Auto Monitoring](stages.md#auto-monitoring)
are skipped.

After all requirements are met, you can [enable Auto DevOps](index.md#enablingdisabling-auto-devops).

## Auto DevOps requirements for Amazon ECS

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208132) in GitLab 13.0.

You can choose to target [AWS ECS](../../ci/cloud_deployment/index.md) as a deployment platform instead of using Kubernetes.

To get started on Auto DevOps to AWS ECS, you must add a specific Environment
Variable. To do so, follow these steps:

1. In your project, go to **Settings > CI / CD** and expand the **Variables**
   section.

1. Specify which AWS platform to target during the Auto DevOps deployment
   by adding the `AUTO_DEVOPS_PLATFORM_TARGET` variable with one of the following values:
   - `FARGATE` if the service you're targeting must be of launch type FARGATE.
   - `ECS` if you're not enforcing any launch type check when deploying to ECS.

When you trigger a pipeline, if you have Auto DevOps enabled and if you have correctly
[entered AWS credentials as environment variables](../../ci/cloud_deployment/index.md#deploy-your-application-to-the-aws-elastic-container-service-ecs),
your application is deployed to AWS ECS.

[GitLab Managed Apps](../../user/clusters/applications.md) are not available when deploying to AWS ECS.
You must manually configure your application (such as Ingress or Help) on AWS ECS.

If you have both a valid `AUTO_DEVOPS_PLATFORM_TARGET` variable and a Kubernetes cluster tied to your project,
only the deployment to Kubernetes runs.

CAUTION: **Warning:**
Setting the `AUTO_DEVOPS_PLATFORM_TARGET` variable to `ECS` triggers jobs
defined in the [`Jobs/Deploy/ECS.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml).
However, it's not recommended to [include](../../ci/yaml/README.md#includetemplate)
it on its own. This template is designed to be used with Auto DevOps only. It may change
unexpectedly causing your pipeline to fail if included on its own. Also, the job
names within this template may also change. Do not override these jobs' names in your
own pipeline, as the override stops working when the name changes.
