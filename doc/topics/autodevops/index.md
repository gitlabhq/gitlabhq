---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Auto DevOps **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38366) in GitLab 11.0.

GitLab Auto DevOps is a collection of pre-configured features and integrations
that work together to support your software delivery process.

Auto DevOps features and integrations:

- Detect your code's language.
- Build and test your application.
- Measure code quality.
- Scan for vulnerabilities and security flaws.
- Check for licensing issues.
- Monitor in real time.
- Deploy your application.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction to Auto DevOps, watch [Auto DevOps in GitLab 11.0](https://youtu.be/0Tc0YYBxqi4).

## Auto DevOps features

Based on the DevOps [stages](stages.md), use Auto DevOps to:

**Build your app:**

- [Auto Build](stages.md#auto-build)
- [Auto Dependency Scanning](stages.md#auto-dependency-scanning)

**Test your app:**

- [Auto Test](stages.md#auto-test)
- [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing)
- [Auto Code Intelligence](stages.md#auto-code-intelligence)
- [Auto Code Quality](stages.md#auto-code-quality)
- [Auto Container Scanning](stages.md#auto-container-scanning)
- [Auto License Compliance](stages.md#auto-license-compliance)

**Deploy your app:**

- [Auto Review Apps](stages.md#auto-review-apps)
- [Auto Deploy](stages.md#auto-deploy)

**Monitor your app:**

- [Auto Monitoring](stages.md#auto-monitoring)

**Secure your app:**

- [Auto Dynamic Application Security Testing (DAST)](stages.md#auto-dast)
- [Auto Static Application Security Testing (SAST)](stages.md#auto-sast)
- [Auto Secret Detection](stages.md#auto-secret-detection)

### How it works

Auto DevOps detects your code language and uses [CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)
to create and run default pipelines. All you need to kick it off is to
[enable](#enable-or-disable-auto-devops) it.

Auto DevOps starts by building and testing your application. Then, based on your
[predefined deployment configuration](requirements.md),
creates the necessary jobs to deploy your apps to staging
and/or production. It also sets up [Review Apps](stages.md#auto-review-apps)
so that you can preview your changes in a per-branch basis.

Note that you don't need to set up the deployment upfront. Auto DevOps
still builds and tests your application. You can define the deployment later.

Auto DevOps avoids the hassle of having to create entire pipelines manually.
Keep it simple and facilitate an iterative approach: ship your app first,
then explore the [customizations](customize.md) later.
You can also [manage Auto DevOps with APIs](customize.md#extend-auto-devops-with-the-api).

Some of the benefits of using Auto DevOps as part of your workflow are:

- Consistency: always start from default templates.
- Simplicity: create your pipeline with the default settings first, iterate later.
- Productivity: deploy multiple apps in a short period of time.
- Efficiency: get things done fast.

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

1. See the [requirements for deployment](requirements.md).
1. [Enable Auto DevOps](#enable-or-disable-auto-devops).
1. Follow the [quick start guide](#quick-start).

As Auto DevOps relies on many components, be familiar with:

- [Continuous methodologies](../../ci/introduction/index.md)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)

When deploying to a Kubernetes cluster make sure you're also familiar with:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Helm](https://helm.sh/docs/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

### Enable or disable Auto DevOps

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41729) in GitLab 11.3, Auto DevOps is enabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26655) GitLab 12.7, Auto DevOps runs pipelines automatically only if a [`Dockerfile` or matching buildpack](stages.md#auto-build) exists.

Depending on your instance type, you can enable or disable Auto DevOps at the
following levels:

| Instance type       | [Project](#at-the-project-level) | [Group](#at-the-group-level) | [Instance](#at-the-instance-level) (Admin Area)  |
|---------------------|------------------------|------------------------|------------------------|
| GitLab SaaS         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| GitLab self-managed | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

Before enabling Auto DevOps, consider [preparing it for deployment](requirements.md). If you don't, Auto DevOps can build and test your app,
but cannot deploy it.

#### At the project level

To use Auto DevOps for individual projects, you can enable it in a
project-by-project basis. If you intend to use it for more projects,
you can enable it for a [group](#at-the-group-level) or an
[instance](#at-the-instance-level). This can save you the time of
enabling it one by one.

Only project Maintainers can enable or disable Auto DevOps at the project level.

Before enabling Auto DevOps, ensure that your project does not have a
`.gitlab-ci.yml` present. If present, your CI/CD configuration takes
precedence over the Auto DevOps pipeline.

To enable Auto DevOps for a project:

1. Go to your project's **Settings > CI/CD > Auto DevOps**.
1. Select the **Default to Auto DevOps pipeline**.
1. (Recommended) Add the [base domain](requirements.md#auto-devops-base-domain).
1. (Recommended) Choose the [deployment strategy](requirements.md#auto-devops-deployment-strategy).
1. Select **Save changes**.

GitLab triggers the Auto DevOps pipeline on the default branch.

To disable it, follow the same process and deselect **Default to Auto
DevOps pipeline**.

#### At the group level

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52447) in GitLab 11.10.

When you enable Auto DevOps at group level, the subgroups and projects in that
group inherit the configuration. This saves you time by batch-enabling it
rather than enabling individually for each subgroup or project.

When enabled for a group, you can still disable Auto DevOps
for the subgroups and projects where you don't want to use it.

Only GitLab administrators and group owners can enable or disable Auto DevOps
at the group level.

To enable Auto DevOps for a group:

1. Go to your group's **Settings > CI/CD > Auto DevOps**.
1. Select **Default to Auto DevOps pipeline**.
1. Select **Save changes**.

After enabling Auto DevOps at the group level, you can trigger the
Auto DevOps pipeline for any project that belongs to that group. To do so:

1. Go to the project's homepage.
1. Make sure the project doesn't contain a `.gitlab-ci.yml` file.
1. From the project's sidebar, go to **CI/CD > Pipelines**.
1. Select **Run pipeline** to trigger the Auto DevOps pipeline.

To disable Auto DevOps on the group level, follow the same process and
deselect **Default to Auto DevOps pipeline**.

#### At the instance level **(FREE SELF)**

By enabling Auto DevOps in the instance level, all projects created in that
instance become enabled. This is convenient when you want to run Auto DevOps by
default for all projects. You can still disable Auto DevOps individually for
the groups and projects where you don't want to run it.

Only GitLab administrators can enable or disable Auto DevOps in the instance
level.

Even when disabled for an instance, group owners and project maintainers
can still enable Auto DevOps at the group and project levels.

To enable Auto DevOps for your instance:

1. From the top bar, select **Menu >** **{admin}** **Admin**.
1. Go to **Settings > CI/CD > Continuous Integration and Deployment**.
1. Select **Default to Auto DevOps pipeline**.
1. (Optional) Add the Auto DevOps [base domain](requirements.md#auto-devops-base-domain).
1. Select **Save changes**.

When enabled, it attempts to run Auto DevOps pipelines in every project. If the
pipeline fails in a particular project, it disables itself.
GitLab administrators can change this in the [Auto DevOps settings](../../user/admin_area/settings/continuous_integration.md#auto-devops).

If a [CI/CD configuration file](../../ci/yaml/index.md) is present,
it remains unchanged and Auto DevOps doesn't affect it.

To disable Auto DevOps in the instance level, follow the same process
and deselect the **Default to Auto DevOps pipeline** checkbox.

### Quick start

To guide your through the process of setting up Auto DevOps to deploy to a Kubernetes cluster on
Google Kubernetes Engine (GKE), see the [quick start guide](quick_start_guide.md).

You can also follow the quick start for the general steps, but deploy to
[AWS ECS](requirements.md#auto-devops-requirements-for-amazon-ecs) instead.

If you're a self-managed user, before deploying to GKE, a GitLab administrator needs to:

1. Configure the [Google OAuth 2.0 OmniAuth Provider](../../integration/google.md).
1. Configure a cluster on GKE.

## Upgrade Auto DevOps dependencies when updating GitLab

When updating GitLab, you may need to upgrade Auto DevOps dependencies to
match your new GitLab version:

- [Upgrading Auto DevOps resources](upgrading_auto_deploy_dependencies.md):
  - Auto DevOps template.
  - Auto Deploy template.
  - Auto Deploy image.
  - Helm.
  - Kubernetes.
  - Environment variables.
- [Upgrading PostgreSQL](upgrading_postgresql.md).

## Limitations

### Private registry support

We cannot guarantee that you can use a private container registry with Auto DevOps.

We strongly advise you to use GitLab Container Registry with Auto DevOps to
simplify configuration and prevent any unforeseen issues.

### Install applications behind a proxy

The GitLab integration with Helm does not support installing applications when
behind a proxy.

To do so, inject proxy settings into the installation pods at runtime.
For example, you can use a [`PodPreset`](https://v1-19.docs.kubernetes.io/docs/concepts/workloads/pods/podpreset/):

```yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: gitlab-managed-apps-default-proxy
  namespace: gitlab-managed-apps
spec:
  env:
    - name: http_proxy
      value: "PUT_YOUR_HTTP_PROXY_HERE"
    - name: https_proxy
      value: "PUT_YOUR_HTTPS_PROXY_HERE"
```

## Troubleshooting

See [troubleshooting Auto DevOps](troubleshooting.md).
