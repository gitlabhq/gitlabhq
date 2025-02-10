---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Requirements for Auto DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Before enabling [Auto DevOps](_index.md), we recommend you to prepare it for
deployment. If you don't, you can use it to build and test your apps, and
then configure the deployment later.

To prepare the deployment:

1. Define the [deployment strategy](#auto-devops-deployment-strategy).
1. Prepare the [base domain](#auto-devops-base-domain).
1. Define where you want to deploy it:

   1. [Kubernetes](#auto-devops-requirements-for-kubernetes).
   1. [Amazon Elastic Container Service (ECS)](cloud_deployments/auto_devops_with_ecs.md).
   1. [Amazon Elastic Kubernetes Service (EKS)](https://about.gitlab.com/blog/2020/05/05/deploying-application-eks/).
   1. [Amazon EC2](cloud_deployments/auto_devops_with_ec2.md).
   1. [Google Kubernetes Engine](cloud_deployments/auto_devops_with_gke.md).
   1. [Bare metal](#auto-devops-requirements-for-bare-metal).

1. [Enable Auto DevOps](_index.md#enable-or-disable-auto-devops).

## Auto DevOps deployment strategy

When using Auto DevOps to deploy your applications, choose the
[continuous deployment strategy](../../ci/_index.md)
that works best for your needs:

| Deployment strategy | Setup | Methodology |
|--|--|--|
| **Continuous deployment to production** | Enables [Auto Deploy](stages.md#auto-deploy) with the default branch continuously deployed to production. | Continuous deployment to production.|
| **Continuous deployment to production using timed incremental rollout** | Sets the [`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#timed-incremental-rollout-to-production) variable to `timed`. | Continuously deploy to production with a 5 minutes delay between rollouts. |
| **Automatic deployment to staging, manual deployment to production** | Sets [`STAGING_ENABLED`](cicd_variables.md#deploy-policy-for-staging-and-production-environments) to `1` and [`INCREMENTAL_ROLLOUT_MODE`](cicd_variables.md#incremental-rollout-to-production) to `manual`. | The default branch is continuously deployed to staging and continuously delivered to production. |

You can choose the deployment method when enabling Auto DevOps or later:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Auto DevOps**.
1. Choose the deployment strategy.
1. Select **Save changes**.

NOTE:
Use the [blue-green deployment](../../ci/environments/incremental_rollouts.md#blue-green-deployment) technique
to minimize downtime and risk.

## Auto DevOps base domain

The Auto DevOps base domain is required to use
[Auto Review Apps](stages.md#auto-review-apps) and [Auto Deploy](stages.md#auto-deploy).

To define the base domain, either:

- In the project, group, or instance level: go to your cluster settings and add it there.
- In the project or group level: add it as an environment variable: `KUBE_INGRESS_BASE_DOMAIN`.
- In the instance level: go to the **Admin** area, then **Settings > CI/CD > Continuous Integration and Delivery** and add it there.

The base domain variable `KUBE_INGRESS_BASE_DOMAIN` follows the same order of
[precedence as other environment variables](../../ci/variables/_index.md#cicd-variable-precedence).

If you don't specify the base domain in your projects and groups, Auto DevOps uses the instance-wide **Auto DevOps domain**.

Auto DevOps requires a wildcard DNS `A` record that matches the base domains. For
a base domain of `example.com`, you'd need a DNS entry like:

```plaintext
*.example.com   3600     A     10.0.2.2
```

In this case, the deployed applications are served from `example.com`, and `10.0.2.2`
is the IP address of your load balancer, generally NGINX ([see requirements](requirements.md)).
Setting up the DNS record is beyond the scope of this document; check with your
DNS provider for information.

Alternatively, you can use free public services like [nip.io](https://nip.io)
which provide automatic wildcard DNS without any configuration. For [nip.io](https://nip.io),
set the Auto DevOps base domain to `10.0.2.2.nip.io`.

After completing setup, all requests hit the load balancer, which routes requests
to the Kubernetes pods running your application.

## Auto DevOps requirements for Kubernetes

To make full use of Auto DevOps with Kubernetes, you need:

- **Kubernetes** (for [Auto Review Apps](stages.md#auto-review-apps) and
  [Auto Deploy](stages.md#auto-deploy))

  To enable deployments, you need:

  1. A [Kubernetes 1.12+ cluster](../../user/infrastructure/clusters/_index.md) for your
     project.
     For Kubernetes 1.16+ clusters, you must perform additional configuration for
     [Auto Deploy for Kubernetes 1.16+](stages.md#kubernetes-116).
  1. For external HTTP traffic, an Ingress controller is required. For regular
     deployments, any Ingress controller should work, but as of GitLab 14.0,
     [canary deployments](../../user/project/canary_deployments.md) require
     NGINX Ingress. You can deploy the NGINX Ingress controller to your
     Kubernetes cluster either through the GitLab [Cluster management project template](../../user/clusters/management_project_template.md)
     or manually by using the [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx)
     Helm chart.

     When deploying [using custom charts](customize.md#custom-helm-chart), you must
     [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
     the Ingress manifest to be scraped by Prometheus using
     `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

     NOTE:
     If your cluster is installed on bare metal, see
     [Auto DevOps Requirements for bare metal](#auto-devops-requirements-for-bare-metal).

- **Base domain** (for [Auto Review Apps](stages.md#auto-review-apps) and
  [Auto Deploy](stages.md#auto-deploy))

  You must [specify the Auto DevOps base domain](#auto-devops-base-domain),
  which all of your Auto DevOps applications use. This domain must be configured
  with wildcard DNS.

- **GitLab Runner** (for all stages)

  Your runner must be configured to run Docker, usually with either the
  [Docker](https://docs.gitlab.com/runner/executors/docker.html)
  or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/index.html) executors, with
  [privileged mode enabled](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode).
  The runners don't need to be installed in the Kubernetes cluster, but the
  Kubernetes executor is easy to use and automatically autoscales.
  You can configure Docker-based runners to autoscale as well, using
  [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html).

  Runners should be registered as [instance runners](../../ci/runners/runners_scope.md#instance-runners)
  for the entire GitLab instance, or [project runners](../../ci/runners/runners_scope.md#project-runners)
  that are assigned to specific projects.

- **cert-manager** (optional, for TLS/HTTPS)

  To enable HTTPS endpoints for your application, you can [install cert-manager](https://cert-manager.io/docs/releases/),
  a native Kubernetes certificate management controller that helps with issuing
  certificates. Installing cert-manager on your cluster issues a
  [Let's Encrypt](https://letsencrypt.org/) certificate and ensures the
  certificates are valid and up-to-date.

If you don't have Kubernetes or Prometheus configured, then
[Auto Review Apps](stages.md#auto-review-apps) and
[Auto Deploy](stages.md#auto-deploy)
are skipped.

After all requirements are met, you can [enable Auto DevOps](_index.md#enable-or-disable-auto-devops).

## Auto DevOps requirements for bare metal

According to the [Kubernetes Ingress-NGINX docs](https://kubernetes.github.io/ingress-nginx/deploy/baremetal/):

> In traditional cloud environments, where network load balancers are available on-demand,
a single Kubernetes manifest suffices to provide a single point of contact to the NGINX Ingress
controller to external clients and, indirectly, to any application running inside the cluster.
Bare-metal environments lack this commodity, requiring a slightly different setup to offer the
same kind of access to external consumers.

The docs linked above explain the issue and present possible solutions, for example:

- Through [MetalLB](https://github.com/metallb/metallb).
- Through [PorterLB](https://github.com/kubesphere/porterlb).
