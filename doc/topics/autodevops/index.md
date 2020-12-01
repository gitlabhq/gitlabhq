---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Auto DevOps

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/37115) in GitLab 10.0.
> - Generally available on GitLab 11.0.

Auto DevOps are default CI/CD templates that auto-discover the source code you have. They
enable GitLab to automatically detect, build, test, deploy, and monitor your applications.
Leveraging [CI/CD best practices](../../ci/pipelines/pipeline_efficiency.md) and tools,
Auto DevOps aims to simplify the setup and execution of a mature and modern software
development lifecycle.

## Overview

You can spend a lot of effort to set up the workflow and processes required to
build, deploy, and monitor your project. It gets worse when your company has
hundreds, if not thousands, of projects to maintain. With new projects
constantly starting up, the entire software development process becomes
impossibly complex to manage.

Auto DevOps provides you a seamless software development process by
automatically detecting all dependencies and language technologies required to
test, build, package, deploy, and monitor every project with minimal
configuration. Automation enables consistency across your projects, seamless
management of processes, and faster creation of new projects: push your code,
and GitLab does the rest, improving your productivity and efficiency.

For an introduction to Auto DevOps, watch [AutoDevOps in GitLab 11.0](https://youtu.be/0Tc0YYBxqi4).

For requirements, see [Requirements for Auto DevOps](requirements.md) for more information.

## Enabled by default

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41729) in GitLab 11.3.

On self-managed instances, Auto DevOps is enabled by default for all projects.
It attempts to run on all pipelines in each project. An instance administrator can
enable or disable this default in the
[Auto DevOps settings](../../user/admin_area/settings/continuous_integration.md#auto-devops).
Auto DevOps automatically disables in individual projects on their first pipeline failure,

NOTE: **Note:**
Auto DevOps is not enabled by default on GitLab.com.

Since [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/-/issues/26655), Auto DevOps
runs on pipelines automatically only if a [`Dockerfile` or matching buildpack](stages.md#auto-build)
exists.

If a [CI/CD configuration file](../../ci/yaml/README.md) is present in the project,
it continues to be used, whether or not Auto DevOps is enabled.

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
  on GitLab's infrastructure. (Note that many features also work without Kubernetes).
- There is no additional cost (no markup on the infrastructure costs), and you
  can use a Kubernetes cluster you host or Containers as a Service on any
  public cloud (for example, [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)).
- Auto DevOps has more features including security testing, performance testing,
  and code quality testing.
- Auto DevOps offers an incremental graduation path. If you need advanced customizations,
  you can start modifying the templates without starting over on a
  completely different platform. Review the [customizing](customize.md) documentation for more information.

## Features

Comprised of a set of [stages](stages.md), Auto DevOps brings these best practices to your
project in a simple and automatic way:

1. [Auto Build](stages.md#auto-build)
1. [Auto Test](stages.md#auto-test)
1. [Auto Code Quality](stages.md#auto-code-quality)
1. [Auto SAST (Static Application Security Testing)](stages.md#auto-sast)
1. [Auto Secret Detection](stages.md#auto-secret-detection)
1. [Auto Dependency Scanning](stages.md#auto-dependency-scanning) **(ULTIMATE)**
1. [Auto License Compliance](stages.md#auto-license-compliance) **(ULTIMATE)**
1. [Auto Container Scanning](stages.md#auto-container-scanning) **(ULTIMATE)**
1. [Auto Review Apps](stages.md#auto-review-apps)
1. [Auto DAST (Dynamic Application Security Testing)](stages.md#auto-dast) **(ULTIMATE)**
1. [Auto Deploy](stages.md#auto-deploy)
1. [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing) **(PREMIUM)**
1. [Auto Monitoring](stages.md#auto-monitoring)
1. [Auto Code Intelligence](stages.md#auto-code-intelligence)

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

NOTE: **Note:**
Kubernetes clusters can [be used without](../../user/project/clusters/index.md)
Auto DevOps.

## Kubernetes requirements

See [Auto DevOps requirements for Kubernetes](requirements.md#auto-devops-requirements-for-kubernetes).

## Auto DevOps base domain

The Auto DevOps base domain is required to use
[Auto Review Apps](stages.md#auto-review-apps), [Auto Deploy](stages.md#auto-deploy), and
[Auto Monitoring](stages.md#auto-monitoring). You can define the base domain in
any of the following places:

- either under the cluster's settings, whether for an instance,
  [projects](../../user/project/clusters/index.md#base-domain) or
  [groups](../../user/group/clusters/index.md#base-domain)
- or at the project level as a variable: `KUBE_INGRESS_BASE_DOMAIN`
- or at the group level as a variable: `KUBE_INGRESS_BASE_DOMAIN`
- or as an instance-wide fallback in **Admin Area > Settings** under the
  **Continuous Integration and Delivery** section

The base domain variable `KUBE_INGRESS_BASE_DOMAIN` follows the same order of precedence
as other environment [variables](../../ci/variables/README.md#priority-of-environment-variables).
If the CI/CD variable is not set and the cluster setting is left blank, the instance-wide **Auto DevOps domain**
setting is used if set.

TIP: **Tip:**
If you use the [GitLab managed app for Ingress](../../user/clusters/applications.md#ingress),
the URL endpoint should be automatically configured for you. All you must do
is use its value for the `KUBE_INGRESS_BASE_DOMAIN` variable.

NOTE: **Note:**
`AUTO_DEVOPS_DOMAIN` was [deprecated in GitLab 11.8](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52363)
and replaced with `KUBE_INGRESS_BASE_DOMAIN`, and removed in
[GitLab 12.0](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/56959).

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

## Enabling/Disabling Auto DevOps

When first using Auto DevOps, review the [requirements](requirements.md) to ensure
all the necessary components to make full use of Auto DevOps are available. First-time
users should follow the [quick start guide](quick_start_guide.md).

GitLab.com users can enable or disable Auto DevOps only at the project level.
Self-managed users can enable or disable Auto DevOps at the project, group, or
instance level.

### At the project level

If enabling, check that your project does not have a `.gitlab-ci.yml`, or if one exists, remove it.

1. Go to your project's **Settings > CI/CD > Auto DevOps**.
1. Select the **Default to Auto DevOps pipeline** checkbox to enable it.
1. (Optional, but recommended) When enabling, you can add in the
   [base domain](#auto-devops-base-domain) Auto DevOps uses to
   [deploy your application](stages.md#auto-deploy),
   and choose the [deployment strategy](#deployment-strategy).
1. Click **Save changes** for the changes to take effect.

After enabling the feature, an Auto DevOps pipeline is triggered on the `master` branch.

### At the group level

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52447) in GitLab 11.10.

Only administrators and group owners can enable or disable Auto DevOps at the group level.

When enabling or disabling Auto DevOps at group level, group configuration is
implicitly used for the subgroups and projects inside that group, unless Auto DevOps
is specifically enabled or disabled on the subgroup or project.

To enable or disable Auto DevOps at the group level:

1. Go to your group's **Settings > CI/CD > Auto DevOps** page.
1. Select the **Default to Auto DevOps pipeline** checkbox to enable it.
1. Click **Save changes** for the changes to take effect.

### At the instance level (Administrators only)

Even when disabled at the instance level, group owners and project maintainers can still enable
Auto DevOps at the group and project level, respectively.

1. Go to **Admin Area > Settings > Continuous Integration and Deployment**.
1. Select **Default to Auto DevOps pipeline for all projects** to enable it.
1. (Optional) You can set up the Auto DevOps [base domain](#auto-devops-base-domain),
   for Auto Deploy and Auto Review Apps to use.
1. Click **Save changes** for the changes to take effect.

### Deployment strategy

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38542) in GitLab 11.0.

You can change the deployment strategy used by Auto DevOps by visiting your
project's **Settings > CI/CD > Auto DevOps**. The following options
are available:

- **Continuous deployment to production**: Enables [Auto Deploy](stages.md#auto-deploy)
  with `master` branch directly deployed to production.
- **Continuous deployment to production using timed incremental rollout**: Sets the
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#timed-incremental-rollout-to-production) variable
  to `timed`. Production deployments execute with a 5 minute delay between
  each increment in rollout.
- **Automatic deployment to staging, manual deployment to production**: Sets the
  [`STAGING_ENABLED`](customize.md#deploy-policy-for-staging-and-production-environments) and
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#incremental-rollout-to-production) variables
  to `1` and `manual`. This means:

  - `master` branch is directly deployed to staging.
  - Manual actions are provided for incremental rollout to production.

TIP: **Tip:**
Use the [blue-green deployment](../../ci/environments/incremental_rollouts.md#blue-green-deployment) technique
to minimize downtime and risk.

## Using multiple Kubernetes clusters

When using Auto DevOps, you can deploy different environments to
different Kubernetes clusters, due to the 1:1 connection
[existing between them](../../user/project/clusters/index.md#multiple-kubernetes-clusters).

The [Deploy Job template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)
used by Auto DevOps currently defines 3 environment names:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

Those environments are tied to jobs using [Auto Deploy](stages.md#auto-deploy), so
except for the environment scope, they must have a different deployment domain.
You must define a separate `KUBE_INGRESS_BASE_DOMAIN` variable for each of the above
[based on the environment](../../ci/variables/README.md#limit-the-environment-scopes-of-environment-variables).

The following table is an example of how to configure the three different clusters:

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` variable value | Variable environment scope | Notes |
|--------------|---------------------------|-------------------------------------------|----------------------------|---|
| review       | `review/*`                | `review.example.com`                      | `review/*`                 | The review cluster which runs all [Review Apps](../../ci/review_apps/index.md). `*` is a wildcard, used by every environment name starting with `review/`. |
| staging      | `staging`                 | `staging.example.com`                     | `staging`                  | (Optional) The staging cluster which runs the deployments of the staging environments. You must [enable it first](customize.md#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                             | `production`               | The production cluster which runs the production environment deployments. You can use [incremental rollouts](customize.md#incremental-rollout-to-production). |

To add a different cluster for each environment:

1. Navigate to your project's **Operations > Kubernetes**.
1. Create the Kubernetes clusters with their respective environment scope, as
   described from the table above.
1. After creating the clusters, navigate to each cluster and install
   Ingress. Wait for the Ingress IP address to be assigned.
1. Make sure you've [configured your DNS](#auto-devops-base-domain) with the
   specified Auto DevOps domains.
1. Navigate to each cluster's page, through **Operations > Kubernetes**,
   and add the domain based on its Ingress IP address.

After completing configuration, you can test your setup by creating a merge request
and verifying your application is deployed as a Review App in the Kubernetes
cluster with the `review/*` environment scope. Similarly, you can check the
other environments.

## Limitations

The following restrictions apply.

### Private registry support

No documented way of using private container registry with Auto DevOps exists.
We strongly advise using GitLab Container Registry with Auto DevOps to
simplify configuration and prevent any unforeseen issues.

### Install applications behind a proxy

GitLab's Helm integration does not support installing applications when
behind a proxy. Users who want to do so must inject their proxy settings
into the installation pods at runtime, such as by using a
[`PodPreset`](https://kubernetes.io/docs/concepts/workloads/pods/podpreset/):

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

### Unable to select a buildpack

Auto Build and Auto Test may fail to detect your language or framework with the
following error:

```plaintext
Step 5/11 : RUN /bin/herokuish buildpack build
 ---> Running in eb468cd46085
    -----> Unable to select a buildpack
The command '/bin/sh -c /bin/herokuish buildpack build' returned a non-zero code: 1
```

The following are possible reasons:

- Your application may be missing the key files the buildpack is looking for.
  Ruby applications require a `Gemfile` to be properly detected,
  even though it's possible to write a Ruby app without a `Gemfile`.
- No buildpack may exist for your application. Try specifying a
  [custom buildpack](customize.md#custom-buildpacks).

### Pipeline that extends Auto DevOps with only / except fails

If your pipeline fails with the following message:

```plaintext
Found errors in your .gitlab-ci.yml:

  jobs:test config key may not be used with `rules`: only
```

This error appears when the included job’s rules configuration has been overridden with the `only` or `except` syntax.
To fix this issue, you must either:

- Transition your `only/except` syntax to rules.
- (Temporarily) Pin your templates to the [GitLab 12.10 based templates](https://gitlab.com/gitlab-org/auto-devops-v12-10).

### Failure to create a Kubernetes namespace

Auto Deploy fails if GitLab can't create a Kubernetes namespace and
service account for your project. For help debugging this issue, see
[Troubleshooting failed deployment jobs](../../user/project/clusters/index.md#troubleshooting).

### Detected an existing PostgreSQL database

After upgrading to GitLab 13.0, you may encounter this message when deploying
with Auto DevOps:

```plaintext
Detected an existing PostgreSQL database installed on the
deprecated channel 1, but the current channel is set to 2. The default
channel changed to 2 in of GitLab 13.0.
[...]
```

Auto DevOps, by default, installs an in-cluster PostgreSQL database alongside
your application. The default installation method changed in GitLab 13.0, and
upgrading existing databases requires user involvement. The two installation
methods are:

- **channel 1 (deprecated):** Pulls in the database as a dependency of the associated
  Helm chart. Only supports Kubernetes versions up to version 1.15.
- **channel 2 (current):** Installs the database as an independent Helm chart. Required
  for using the in-cluster database feature with Kubernetes versions 1.16 and greater.

If you receive this error, you can do one of the following actions:

- You can *safely* ignore the warning and continue using the channel 1 PostgreSQL
  database by setting `AUTO_DEVOPS_POSTGRES_CHANNEL` to `1` and redeploying.

- You can delete the channel 1 PostgreSQL database and install a fresh channel 2
  database by setting `AUTO_DEVOPS_POSTGRES_DELETE_V1` to a non-empty value and
  redeploying.

  DANGER: **Warning:**
  Deleting the channel 1 PostgreSQL database permanently deletes the existing
  channel 1 database and all its data. See
  [Upgrading PostgreSQL](upgrading_postgresql.md)
  for more information on backing up and upgrading your database.

- If you are not using the in-cluster database, you can set
  `POSTGRES_ENABLED` to `false` and re-deploy. This option is especially relevant to
  users of *custom charts without the in-chart PostgreSQL dependency*.
  Database auto-detection is based on the `postgresql.enabled` Helm value for
  your release. This value is set based on the `POSTGRES_ENABLED` CI variable
  and persisted by Helm, regardless of whether or not your chart uses the
  variable.

DANGER: **Warning:**
Setting `POSTGRES_ENABLED` to `false` permanently deletes any existing
channel 1 database for your environment.

### Error: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"

After upgrading your Kubernetes cluster to [v1.16+](stages.md#kubernetes-116),
you may encounter this message when deploying with Auto DevOps:

```plaintext
UPGRADE FAILED
Error: failed decoding reader into objects: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"
```

This can occur if your current deployments on the environment namespace were deployed with a
deprecated/removed API that doesn't exist in Kubernetes v1.16+. For example,
if [your in-cluster PostgreSQL was installed in a legacy way](#detected-an-existing-postgresql-database),
the resource was created via the `extensions/v1beta1` API. However, the deployment resource
was moved to the `app/v1` API in v1.16.

To recover such outdated resources, you must convert the current deployments by mapping legacy APIs
to newer APIs. There is a helper tool called [`mapkubeapis`](https://github.com/hickeyma/helm-mapkubeapis)
that works for this problem. Follow these steps to use the tool in Auto DevOps:

1. Modify your `.gitlab-ci.yml` with:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
     - remote: https://gitlab.com/shinya.maeda/ci-templates/-/raw/master/map-deprecated-api.gitlab-ci.yml

   variables:
     HELM_VERSION_FOR_MAPKUBEAPIS: "v2" # If you're using auto-depoy-image v2 or above, please specify "v3".
   ```

1. Run the job `<environment-name>:map-deprecated-api`. Ensure that this job succeeds before moving
   to the next step. You should see something like the following output:

   ```shell
   2020/10/06 07:20:49 Found deprecated or removed Kubernetes API:
   "apiVersion: extensions/v1beta1
   kind: Deployment"
   Supported API equivalent:
   "apiVersion: apps/v1
   kind: Deployment"
   ```

1. Revert your `.gitlab-ci.yml` to the previous version. You no longer need to include the
   supplemental template `map-deprecated-api`.

1. Continue the deployments as usual.

### Error: error initializing: Looks like "https://kubernetes-charts.storage.googleapis.com" is not a valid chart repository or cannot be reached

As [announced in the official CNCF blogpost](https://www.cncf.io/blog/2020/10/07/important-reminder-for-all-helm-users-stable-incubator-repos-are-deprecated-and-all-images-are-changing-location/),
the stable Helm chart repository was deprecated and removed on November 13th, 2020.
You may encounter this error after that date.

Some GitLab features had dependencies on the stable chart. To mitigate the impact, we changed them
to use new official repositories or the [Helm Stable Archive repository maintained by GitLab](https://gitlab.com/gitlab-org/cluster-integration/helm-stable-archive).
Auto Deploy contains [an example fix](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/merge_requests/127).

In Auto Deploy, `v1.0.6+` of `auto-deploy-image` no longer adds the deprecated stable repository to
the `helm` command. If you use a custom chart and it relies on the deprecated stable repository,
specify an older `auto-deploy-image` like this example:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

.auto-deploy:
  image: "registry.gitlab.com/gitlab-org/cluster-integration/auto-deploy-image:v1.0.5"
```

Keep in mind that this approach stops working when the stable repository is removed,
so you must eventually fix your custom chart.

To fix your custom chart:

1. In your chart directory, update the `repository` value in your `requirements.yaml` file from :

   ```yaml
   repository: "https://kubernetes-charts.storage.googleapis.com/"
   ```

   to:

   ```yaml
   repository: "https://charts.helm.sh/stable"
   ```

1. In your chart directory, run `helm dep update .` using the same Helm major version as Auto DevOps.
1. Commit the changes for the `requirements.yaml` file.
1. If you previously had a `requirements.lock` file, commit the changes to the file.
   If you did not previously have a `requirements.lock` file in your chart,
   you do not need to commit the new one. This file is optional, but when present,
   it's used to verify the integrity of the downloaded dependencies.

You can find more information in
[issue #263778, "Migrate PostgreSQL from stable Helm repo"](https://gitlab.com/gitlab-org/gitlab/-/issues/263778).

### Error: release .... failed: timed out waiting for the condition

When getting started with Auto DevOps, you may encounter this error when first
deploying your application:

```plaintext
INSTALL FAILED
PURGING CHART
Error: release staging failed: timed out waiting for the condition
```

This is most likely caused by a failed liveness (or readiness) probe attempted
during the deployment process. By default, these probes are run against the root
page of the deployed application on port 5000. If your application isn't configured
to serve anything at the root page, or is configured to run on a specific port
*other* than 5000, this check fails.

If it fails, you should see these failures within the events for the relevant
Kubernetes namespace. These events look like the following example:

```plaintext
LAST SEEN   TYPE      REASON                   OBJECT                                            MESSAGE
3m20s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Readiness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
3m32s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Liveness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
```

To change the port used for the liveness checks, pass
[custom values to the Helm chart](customize.md#customize-values-for-helm-chart)
used by Auto DevOps:

1. Create a directory and file at the root of your repository named `.gitlab/auto-deploy-values.yaml`.

1. Populate the file with the following content, replacing the port values with
   the actual port number your application is configured to use:

   ```yaml
   service:
     internalPort: <port_value>
     externalPort: <port_value>
   ```

1. Commit your changes.

After committing your changes, subsequent probes should use the newly-defined ports.
The page that's probed can also be changed by overriding the `livenessProbe.path`
and `readinessProbe.path` values (shown in the
[default `values.yaml`](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/blob/master/assets/auto-deploy-app/values.yaml)
file) in the same fashion.

## Development guides

[Development guide for Auto DevOps](../../development/auto_devops.md)
