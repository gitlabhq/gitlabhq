---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Auto DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab Auto DevOps is a collection of pre-configured features and integrations
that work together to support your software delivery process.

Auto DevOps detects your programming language and uses [CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)
to create and run default pipelines to build and test your application. Then, you can [configure deployments](requirements.md) to deploy your apps to staging
and production, and set up [review apps](stages.md#auto-review-apps)
to preview your changes per branch.

You can use default settings to quickly ship your apps, and iterate and [customize](customize.md) later.

You can also [manage Auto DevOps with APIs](customize.md#extend-auto-devops-with-the-api).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction to Auto DevOps, watch [Auto DevOps](https://youtu.be/0Tc0YYBxqi4).
<!-- Video published on 2018-06-22 -->

## Auto DevOps features

Auto DevOps supports development during each of the [DevOps stages](stages.md).

| Stage | Auto DevOps feature |
|---------|-------------|
| Build | [Auto Build](stages.md#auto-build) |
| Build | [Auto Dependency Scanning](stages.md#auto-dependency-scanning) |
| Test | [Auto Test](stages.md#auto-test) |
| Test | [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing) |
| Test | [Auto Code Intelligence](stages.md#auto-code-intelligence) |
| Test | [Auto Code Quality](stages.md#auto-code-quality) |
| Test | [Auto Container Scanning](stages.md#auto-container-scanning) |
| Deploy | [Auto Review Apps](stages.md#auto-review-apps) |
| Deploy | [Auto Deploy](stages.md#auto-deploy) |
| Secure | [Auto Dynamic Application Security Testing (DAST)](stages.md#auto-dast) |
| Secure | [Auto Static Application Security Testing (SAST)](stages.md#auto-sast) |
| Secure | [Auto Secret Detection](stages.md#auto-secret-detection) |

### Comparison to application platforms and PaaS

Auto DevOps provides features often included in an application
platform or in a Platform as a Service (PaaS).

Inspired by [Heroku](https://www.heroku.com/), Auto DevOps goes beyond it
in multiple ways:

- Auto DevOps works with any Kubernetes cluster.
- There is no additional cost.
- You can use a cluster hosted by yourself or on any public cloud.
- Auto DevOps offers an incremental graduation path. If you need to [customize](customize.md), start by changing the templates and evolve from there.

## Get started with Auto DevOps

To get started, you only need to [enable Auto DevOps](#enable-or-disable-auto-devops).
This is enough to run an Auto DevOps pipeline to build and
test your application.

If you want to build, test, and deploy your app:

1. View the [requirements for deployment](requirements.md).
1. [Enable Auto DevOps](#enable-or-disable-auto-devops).
1. [Deploy your app to a cloud provider](#deploy-your-app-to-a-cloud-provider).

### Enable or disable Auto DevOps

Auto DevOps runs pipelines automatically only if a [`Dockerfile` or matching buildpack](stages.md#auto-build) exists.

You can enable or disable Auto DevOps for a project or an entire group. Instance administrators
can also [set Auto DevOps as the default](../../administration/settings/continuous_integration.md#auto-devops)
for all projects in an instance.

Before enabling Auto DevOps, consider [preparing it for deployment](requirements.md).
If you don't, Auto DevOps can build and test your app, but cannot deploy it.

#### Per project

To use Auto DevOps for individual projects, you can enable it in a
project-by-project basis. If you intend to use it for more projects,
you can enable it for a [group](#per-group) or an
[instance](../../administration/settings/continuous_integration.md#auto-devops).
This can save you the time of enabling it in each project.

Prerequisites:

- You must have at least the Maintainer role for the project.
- Ensure your project does not have a `.gitlab-ci.yml` present. If present, your CI/CD configuration takes
  precedence over the Auto DevOps pipeline.

To enable Auto DevOps for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Auto DevOps**.
1. Select the **Default to Auto DevOps pipeline** checkbox.
1. Optional but recommended. Add the [base domain](requirements.md#auto-devops-base-domain).
1. Optional but recommended. Choose the [deployment strategy](requirements.md#auto-devops-deployment-strategy).
1. Select **Save changes**.

GitLab triggers the Auto DevOps pipeline on the default branch.

To disable it, follow the same process and clear the
**Default to Auto DevOps pipeline** checkbox.

#### Per group

When you enable Auto DevOps for a group, the subgroups and
projects in that group inherit the configuration. You can save time by
enabling Auto DevOps for a group instead of enabling it for each
subgroup or project.

When enabled for a group, you can still disable Auto DevOps
for the subgroups and projects where you don't want to use it.

Prerequisites:

- You must have the Owner role for the group.

To enable Auto DevOps for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > CI/CD**.
1. Expand **Auto DevOps**.
1. Select the **Default to Auto DevOps pipeline** checkbox.
1. Select **Save changes**.

To disable Auto DevOps for a group, follow the same process and
clear the **Default to Auto DevOps pipeline** checkbox.

After enabling Auto DevOps for a group, you can trigger the
Auto DevOps pipeline for any project that belongs to that group:

1. On the left sidebar, select **Search or go to** and find your project.
1. Make sure the project doesn't contain a `.gitlab-ci.yml` file.
1. Select **Build > Pipelines**.
1. To trigger the Auto DevOps pipeline, select **New pipeline**.

### Deploy your app to a cloud provider

- [Use Auto DevOps to deploy to a Kubernetes cluster on Google Kubernetes Engine (GKE)](cloud_deployments/auto_devops_with_gke.md)
- [Use Auto DevOps to deploy to a Kubernetes cluster on Amazon Elastic Kubernetes Service (EKS)](cloud_deployments/auto_devops_with_eks.md)
- [Use Auto DevOps to deploy to EC2](cloud_deployments/auto_devops_with_ec2.md)
- [Use Auto DevOps to deploy to ECS](cloud_deployments/auto_devops_with_ecs.md)

## Upgrade Auto DevOps dependencies when updating GitLab

When updating GitLab, you might need to upgrade Auto DevOps dependencies to
match your new GitLab version:

- [Upgrading Auto DevOps resources](upgrading_auto_deploy_dependencies.md):
  - Auto DevOps template.
  - Auto Deploy template.
  - Auto Deploy image.
  - Helm.
  - Kubernetes.
  - Environment variables.
- [Upgrading PostgreSQL](upgrading_postgresql.md).

## Private registry support

There is no guarantee that you can use a private container registry with Auto DevOps.

Instead, use the [GitLab container registry](../../user/packages/container_registry/_index.md) with Auto DevOps to
simplify configuration and prevent any unforeseen issues.

## Install applications behind a proxy

The GitLab integration with Helm does not support installing applications when
behind a proxy.

If you want to do so, you must inject proxy settings into the
installation pods at runtime.

## Related topics

- [Continuous methodologies](../../ci/_index.md)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Helm](https://helm.sh/docs/)
- [Kubernetes](https://kubernetes.io/docs/home/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

## Troubleshooting

See [troubleshooting Auto DevOps](troubleshooting.md).
