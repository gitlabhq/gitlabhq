---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Auto DevOps **(FREE)**

> - Introduced in GitLab 11.0 for general availability.

GitLab Auto DevOps helps to reduce the complexity of software delivery by
setting up pipelines and integrations for you. Instead of requiring you to
manually configure your entire GitLab environment, Auto DevOps configures
many of these areas for you, including security auditing and vulnerability
testing.

Using Auto DevOps, you can:

- Detect the language of your code.
- Automatically build, test, and measure code quality.
- Scan for potential vulnerabilities, security flaws, and licensing issues.
- Monitor in real-time.
- Deploy your application.

The functionality of Auto DevOps is based on default CI/CD templates that
auto-discover your source code. These templates enable GitLab to provide
consistency across your projects, seamless management of processes, and faster
creation of new projects. Leveraging [CI/CD best practices](../../ci/pipelines/pipeline_efficiency.md)
and tools, Auto DevOps lets you push your code, with GitLab doing the rest,
improving your productivity and efficiency.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction to Auto DevOps, watch [AutoDevOps in GitLab 11.0](https://youtu.be/0Tc0YYBxqi4) or see this [overview](https://about.gitlab.com/stages-devops-lifecycle/auto-devops/).

For requirements, read [Requirements for Auto DevOps](requirements.md) for more information.

For GitLab contributors, see the [Auto DevOps development guide](../../development/auto_devops.md).

## Enable or disable Auto DevOps

Auto DevOps is enabled by default for all projects in self-managed instances
(as of [GitLab 11.3](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41729)),
but not for GitLab SaaS instances.

When first using Auto DevOps, review the [requirements](requirements.md) to
ensure all the necessary components to make full use of Auto DevOps are
available. First-time users should follow the [quick start guide](quick_start_guide.md).

Depending on your instance type, you can enable or disable Auto DevOps at the
following levels:

| Instance type       | [Project](#at-the-project-level) | [Group](#at-the-group-level) | [Instance](#at-the-instance-level) (Admin Area)  |
|---------------------|------------------------|------------------------|------------------------|
| GitLab SaaS         | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| GitLab self-managed | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |

When you enable AutoDevOps for your instance, it attempts to run on all
pipelines in each project, but will automatically disable itself for individual
projects on their first pipeline failure. An instance administrator can enable
or disable this default in the [Auto DevOps settings](../../user/admin_area/settings/continuous_integration.md#auto-devops).

Since [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/issues/26655),
Auto DevOps runs on pipelines automatically only if a [`Dockerfile` or matching buildpack](stages.md#auto-build)
exists.

If a [CI/CD configuration file](../../ci/yaml/index.md) is present in the
project, it isn't changed and won't be affected by Auto DevOps.

### At the project level

When you enable Auto DevOps for a project, ensure that your project does not have a `.gitlab-ci.yml` present. If it exists, remove it before enabling Auto DevOps.

To enable it:

1. Go to your project's **Settings > CI/CD > Auto DevOps**.
1. Select the **Default to Auto DevOps pipeline** checkbox to enable it.
1. (Optional, but recommended) When enabling, you can add in the
   [base domain](#auto-devops-base-domain) Auto DevOps uses to
   [deploy your application](stages.md#auto-deploy),
   and choose the [deployment strategy](#deployment-strategy).
1. Click **Save changes** for the changes to take effect.

After enabling the feature, an Auto DevOps pipeline is triggered on the default branch.

### At the group level

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52447) in GitLab 11.10.

Only administrators and group owners can enable or disable Auto DevOps at the group level.

When enabling or disabling Auto DevOps at group level, group configuration is
implicitly used for the subgroups and projects inside that group, unless Auto DevOps
is specifically enabled or disabled on the subgroup or project.

To enable or disable Auto DevOps at the group level:

1. Go to your group's **Settings > CI/CD > Auto DevOps** page.
1. Select the **Default to Auto DevOps pipeline** checkbox to enable it.
1. Click **Save changes** for the changes to take effect.

### At the instance level **(FREE SELF)**

Even when disabled at the instance level, group owners and project maintainers
can still enable Auto DevOps at the group and project level, respectively.

1. As an administrator, on the top bar, select **Menu >** **{admin}** **Admin**.
1. Go to **Settings > CI/CD > Continuous Integration and Deployment**.
1. Select **Default to Auto DevOps pipeline for all projects** to enable it.
1. (Optional) You can set up the Auto DevOps [base domain](#auto-devops-base-domain),
   for Auto Deploy and Auto Review Apps to use.
1. Click **Save changes** for the changes to take effect.

### Deployment strategy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38542) in GitLab 11.0.

You can change the deployment strategy used by Auto DevOps by visiting your
project's **Settings > CI/CD > Auto DevOps**. The following options
are available:

- **Continuous deployment to production**: Enables [Auto Deploy](stages.md#auto-deploy)
  with the default branch directly deployed to production.
- **Continuous deployment to production using timed incremental rollout**: Sets the
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#timed-incremental-rollout-to-production) variable
  to `timed`. Production deployments execute with a 5 minute delay between
  each increment in rollout.
- **Automatic deployment to staging, manual deployment to production**: Sets the
  [`STAGING_ENABLED`](customize.md#deploy-policy-for-staging-and-production-environments) and
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#incremental-rollout-to-production) variables
  to `1` and `manual`. This means:

  - The default branch is directly deployed to staging.
  - Manual actions are provided for incremental rollout to production.

NOTE:
Use the [blue-green deployment](../../ci/environments/incremental_rollouts.md#blue-green-deployment) technique
to minimize downtime and risk.

## Quick start

If you're using GitLab.com, see the [quick start guide](quick_start_guide.md)
for setting up Auto DevOps with GitLab.com and a Kubernetes cluster on Google Kubernetes
Engine (GKE).

If you use a self-managed instance of GitLab, you must configure the
[Google OAuth2 OmniAuth Provider](../../integration/google.md) before
configuring a cluster on GKE. After configuring the provider, you can follow
the steps in the [quick start guide](quick_start_guide.md) to get started.

In [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/208132) and later, it is
possible to leverage Auto DevOps to deploy to [AWS ECS](requirements.md#auto-devops-requirements-for-amazon-ecs).

## Comparison to application platforms and PaaS

Auto DevOps provides features often included in an application
platform or a Platform as a Service (PaaS). It takes inspiration from the
innovative work done by [Heroku](https://www.heroku.com/) and goes beyond it
in multiple ways:

- Auto DevOps works with any Kubernetes cluster; you're not limited to running
  on infrastructure managed by GitLab. (Note that many features also work without Kubernetes).
- There is no additional cost (no markup on the infrastructure costs), and you
  can use a Kubernetes cluster you host or Containers as a Service on any
  public cloud (for example, [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)).
- Auto DevOps has more features including security testing, performance testing,
  and code quality testing.
- Auto DevOps offers an incremental graduation path. If you need advanced customizations,
  you can start modifying the templates without starting over on a
  completely different platform. Review the [customizing](customize.md) documentation for more information.

## Features

NOTE:
Depending on your target platform, some features might not be available to you.

Comprised of a set of [stages](stages.md), Auto DevOps brings these best practices to your
project in a simple and automatic way:

- [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing)
- [Auto Build](stages.md#auto-build)
- [Auto Code Intelligence](stages.md#auto-code-intelligence)
- [Auto Code Quality](stages.md#auto-code-quality)
- [Auto Container Scanning](stages.md#auto-container-scanning)
- [Auto DAST (Dynamic Application Security Testing)](stages.md#auto-dast)
- [Auto Dependency Scanning](stages.md#auto-dependency-scanning)
- [Auto Deploy](stages.md#auto-deploy)
- [Auto License Compliance](stages.md#auto-license-compliance)
- [Auto Monitoring](stages.md#auto-monitoring)
- [Auto Review Apps](stages.md#auto-review-apps)
- [Auto SAST (Static Application Security Testing)](stages.md#auto-sast)
- [Auto Secret Detection](stages.md#auto-secret-detection)
- [Auto Test](stages.md#auto-test)

As Auto DevOps relies on many different components, you should have a basic
knowledge of the following:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Helm](https://helm.sh/docs/)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

Auto DevOps provides great defaults for all the stages and makes use of
[CI templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates). You can, however,
[customize](customize.md) almost everything to your needs, and
[manage Auto DevOps with GitLab APIs](customize.md#extend-auto-devops-with-the-api).

For an overview on the creation of Auto DevOps, read more
[in this blog post](https://about.gitlab.com/blog/2017/06/29/whats-next-for-gitlab-ci/).

NOTE:
Kubernetes clusters can [be used without](../../user/project/clusters/index.md)
Auto DevOps.

## Kubernetes requirements

See [Auto DevOps requirements for Kubernetes](requirements.md#auto-devops-requirements-for-kubernetes).

## Auto DevOps base domain

The Auto DevOps base domain is required to use
[Auto Review Apps](stages.md#auto-review-apps), [Auto Deploy](stages.md#auto-deploy), and
[Auto Monitoring](stages.md#auto-monitoring). You can define the base domain in
any of the following places:

- Either under the cluster's settings, whether for an instance,
  [projects](../../user/project/clusters/gitlab_managed_clusters.md#base-domain) or
  [groups](../../user/group/clusters/index.md#base-domain)
- Or at the project level as a variable: `KUBE_INGRESS_BASE_DOMAIN`
- Or at the group level as a variable: `KUBE_INGRESS_BASE_DOMAIN`
- Or as an instance-wide fallback in **Menu >** **{admin}** **Admin >**
  **Settings > CI/CD** under the **Continuous Integration and Delivery** section.

The base domain variable `KUBE_INGRESS_BASE_DOMAIN` follows the same order of precedence
as other environment [variables](../../ci/variables/index.md#cicd-variable-precedence).
If the CI/CD variable is not set and the cluster setting is left blank, the instance-wide **Auto DevOps domain**
setting is used if set.

Auto DevOps requires a wildcard DNS A record matching the base domain(s). For
a base domain of `example.com`, you'd need a DNS entry like:

```plaintext
*.example.com   3600     A     1.2.3.4
```

In this case, the deployed applications are served from `example.com`, and `1.2.3.4`
is the IP address of your load balancer; generally NGINX ([see requirements](requirements.md)).
Setting up the DNS record is beyond the scope of this document; check with your
DNS provider for information.

Alternatively, you can use free public services like [nip.io](https://nip.io)
which provide automatic wildcard DNS without any configuration. For [nip.io](https://nip.io),
set the Auto DevOps base domain to `1.2.3.4.nip.io`.

After completing setup, all requests hit the load balancer, which routes requests
to the Kubernetes pods running your application.

### AWS ECS

See [Auto DevOps requirements for Amazon ECS](requirements.md#auto-devops-requirements-for-amazon-ecs).

## Using multiple Kubernetes clusters

When using Auto DevOps, you can deploy different environments to
different Kubernetes clusters, due to the 1:1 connection
[existing between them](../../user/project/clusters/multiple_kubernetes_clusters.md).

The [Deploy Job template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)
used by Auto DevOps currently defines 3 environment names:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

Those environments are tied to jobs using [Auto Deploy](stages.md#auto-deploy), so
except for the environment scope, they must have a different deployment domain.
You must define a separate `KUBE_INGRESS_BASE_DOMAIN` variable for each of the above
[based on the environment](../../ci/variables/index.md#limit-the-environment-scope-of-a-cicd-variable).

The following table is an example of how to configure the three different clusters:

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` variable value | Variable environment scope | Notes |
|--------------|---------------------------|-------------------------------------------|----------------------------|---|
| review       | `review/*`                | `review.example.com`                      | `review/*`                 | The review cluster which runs all [Review Apps](../../ci/review_apps/index.md). `*` is a wildcard, used by every environment name starting with `review/`. |
| staging      | `staging`                 | `staging.example.com`                     | `staging`                  | (Optional) The staging cluster which runs the deployments of the staging environments. You must [enable it first](customize.md#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                             | `production`               | The production cluster which runs the production environment deployments. You can use [incremental rollouts](customize.md#incremental-rollout-to-production). |

To add a different cluster for each environment:

1. Navigate to your project's **Infrastructure > Kubernetes clusters**.
1. Create the Kubernetes clusters with their respective environment scope, as
   described from the table above.
1. After creating the clusters, navigate to each cluster and [install
   Ingress](quick_start_guide.md#install-ingress). Wait for the Ingress IP address to be assigned.
1. Make sure you've [configured your DNS](#auto-devops-base-domain) with the
   specified Auto DevOps domains.
1. Navigate to each cluster's page, through **Infrastructure > Kubernetes clusters**,
   and add the domain based on its Ingress IP address.

After completing configuration, you can test your setup by creating a merge request
and verifying your application is deployed as a Review App in the Kubernetes
cluster with the `review/*` environment scope. Similarly, you can check the
other environments.

[Cluster environment scope isn't respected](https://gitlab.com/gitlab-org/gitlab/-/issues/20351)
when checking for active Kubernetes clusters. For multi-cluster setup to work with Auto DevOps,
create a fallback cluster with **Cluster environment scope** set to `*`. A new cluster isn't
required. You can use any of the clusters already added.

## Limitations

The following restrictions apply.

### Private registry support

No documented way of using private container registry with Auto DevOps exists.
We strongly advise using GitLab Container Registry with Auto DevOps to
simplify configuration and prevent any unforeseen issues.

### Install applications behind a proxy

The GitLab integration with Helm does not support installing applications when
behind a proxy. Users who want to do so must inject their proxy settings
into the installation pods at runtime, such as by using a
[`PodPreset`](https://v1-19.docs.kubernetes.io/docs/concepts/workloads/pods/podpreset/):

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

<!-- DO NOT ADD TROUBLESHOOTING INFO HERE -->
<!-- Troubleshooting information has moved to troubleshooting.md -->
