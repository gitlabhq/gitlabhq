# Auto DevOps

> - [Introduced][ce-37115] in GitLab 10.0.
> - Generally available on GitLab 11.0.

Auto DevOps provides pre-defined CI/CD configuration which allows you to automatically detect, build, test,
deploy, and monitor your applications. Leveraging CI/CD best practices and tools, Auto DevOps aims
to simplify the setup and execution of a mature & modern software development lifecycle.

## Overview

With Auto DevOps, the software development process becomes easier to set up
as every project can have a complete workflow from verification to monitoring
with minimal configuration. Just push your code and GitLab takes
care of everything else. This makes it easier to start new projects and brings
consistency to how applications are set up throughout a company.

For an introduction to Auto DevOps, watch [AutoDevOps in GitLab 11.0](https://youtu.be/0Tc0YYBxqi4).

## Enabled by default

Starting with GitLab 11.3, the Auto DevOps pipeline is enabled by default for all
projects. If it has not been explicitly enabled for the project, Auto DevOps will be automatically
disabled on the first pipeline failure. Your project will continue to use an alternative
[CI/CD configuration file](../../ci/yaml/README.md) if one is found. A GitLab
administrator can [change this setting](../../user/admin_area/settings/continuous_integration.md#auto-devops-core-only)
in the admin area.

## Quick start

If you are using GitLab.com, see the [quick start guide](quick_start_guide.md)
for how to use Auto DevOps with GitLab.com and a Kubernetes cluster on Google Kubernetes
Engine (GKE).

If you are using a self-hosted instance of GitLab, you will need to configure the
[Google OAuth2 OmniAuth Provider](../../integration/google.md) before
you can configure a cluster on GKE. Once this is set up, you can follow the steps on the
[quick start guide](quick_start_guide.md) to get started.

## Comparison to application platforms and PaaS

Auto DevOps provides functionality that is often included in an application
platform or a Platform as a Service (PaaS). It takes inspiration from the
innovative work done by [Heroku](https://www.heroku.com/) and goes beyond it
in multiple ways:

- Auto DevOps works with any Kubernetes cluster; you're not limited to running
  on GitLab's infrastructure. (Note that many features also work without Kubernetes).
- There is no additional cost (no markup on the infrastructure costs), and you
  can use a self-hosted Kubernetes cluster or Containers as a Service on any
  public cloud (for example, [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)).
- Auto DevOps has more features including security testing, performance testing,
  and code quality testing.
- Auto DevOps offers an incremental graduation path. If you need advanced customizations,
  you can start modifying the templates without having to start over on a
  completely different platform. Review the [customizing](#customizing) section for more information.

## Features

Comprised of a set of stages, Auto DevOps brings these best practices to your
project in a simple and automatic way:

1. [Auto Build](#auto-build)
1. [Auto Test](#auto-test)
1. [Auto Code Quality](#auto-code-quality-starter) **(STARTER)**
1. [Auto SAST (Static Application Security Testing)](#auto-sast-ultimate) **(ULTIMATE)**
1. [Auto Dependency Scanning](#auto-dependency-scanning-ultimate) **(ULTIMATE)**
1. [Auto License Compliance](#auto-license-compliance-ultimate) **(ULTIMATE)**
1. [Auto Container Scanning](#auto-container-scanning-ultimate) **(ULTIMATE)**
1. [Auto Review Apps](#auto-review-apps)
1. [Auto DAST (Dynamic Application Security Testing)](#auto-dast-ultimate) **(ULTIMATE)**
1. [Auto Deploy](#auto-deploy)
1. [Auto Browser Performance Testing](#auto-browser-performance-testing-premium) **(PREMIUM)**
1. [Auto Monitoring](#auto-monitoring)

As Auto DevOps relies on many different components, it's good to have a basic
knowledge of the following:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Helm](https://helm.sh/docs/)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

Auto DevOps provides great defaults for all the stages; you can, however,
[customize](#customizing) almost everything to your needs.

For an overview on the creation of Auto DevOps, read the blog post [From 2/3 of the Self-Hosted Git Market, to the Next-Generation CI System, to Auto DevOps](https://about.gitlab.com/blog/2017/06/29/whats-next-for-gitlab-ci/).

NOTE: **Note**
Kubernetes clusters can [be used without](../../user/project/clusters/index.md)
Auto DevOps.

## Requirements

To make full use of Auto DevOps, you will need:

- **Kubernetes** (for Auto Review Apps, Auto Deploy, and Auto Monitoring)

  To enable deployments, you will need:

  1. A [Kubernetes 1.12+ cluster](../../user/project/clusters/index.md) for the project. The easiest
     way is to add a [new cluster using the GitLab UI](../../user/project/clusters/add_remove_clusters.md#add-new-cluster).
  1. NGINX Ingress. You can deploy it to your Kubernetes cluster by installing
     the [GitLab-managed app for Ingress](../../user/clusters/applications.md#ingress),
     once you have configured GitLab's Kubernetes integration in the previous step.

     Alternatively, you can use the
     [`nginx-ingress`](https://github.com/helm/charts/tree/master/stable/nginx-ingress)
     Helm chart to install Ingress manually.

     NOTE: **Note:**
     If you are using your own Ingress instead of the one provided by GitLab's managed
     apps, ensure you are running at least version 0.9.0 of NGINX Ingress and
     [enable Prometheus metrics](https://github.com/helm/charts/tree/master/stable/nginx-ingress#prometheus-metrics)
     in order for the response metrics to appear. You will also have to
     [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
     the NGINX Ingress deployment to be scraped by Prometheus using
     `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

- **Base domain** (for Auto Review Apps, Auto Deploy, and Auto Monitoring)

  You will need a domain configured with wildcard DNS which is going to be used
  by all of your Auto DevOps applications. If you're using the
  [GitLab-managed app for Ingress](../../user/clusters/applications.md#ingress),
  the URL endpoint will be automatically configured for you.

  You will then need to [specify the Auto DevOps base domain](#auto-devops-base-domain).

- **GitLab Runner** (for all stages)

  Your Runner needs to be configured to be able to run Docker. Generally this
  means using either the [Docker](https://docs.gitlab.com/runner/executors/docker.html)
  or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html) executors, with
  [privileged mode enabled](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode).
  The Runners do not need to be installed in the Kubernetes cluster, but the
  Kubernetes executor is easy to use and is automatically autoscaling.
  Docker-based Runners can be configured to autoscale as well, using [Docker
  Machine](https://docs.gitlab.com/runner/install/autoscaling.html).

  If you have configured GitLab's Kubernetes integration in the first step, you
  can deploy it to your cluster by installing the
  [GitLab-managed app for GitLab Runner](../../user/clusters/applications.md#gitlab-runner).

  Runners should be registered as [shared Runners](../../ci/runners/README.md#registering-a-shared-runner)
  for the entire GitLab instance, or [specific Runners](../../ci/runners/README.md#registering-a-specific-runner)
  that are assigned to specific projects (the default if you have installed the
  GitLab Runner managed application).

- **Prometheus** (for Auto Monitoring)

  To enable Auto Monitoring, you will need Prometheus installed somewhere
  (inside or outside your cluster) and configured to scrape your Kubernetes cluster.
  If you have configured GitLab's Kubernetes integration, you can deploy it to
  your cluster by installing the
  [GitLab-managed app for Prometheus](../../user/clusters/applications.md#prometheus).

  The [Prometheus service](../../user/project/integrations/prometheus.md)
  integration needs to be enabled for the project (or enabled as a
  [default service template](../../user/project/integrations/services_templates.md)
  for the entire GitLab installation).

  To get response metrics (in addition to system metrics), you need to
  [configure Prometheus to monitor NGINX](../../user/project/integrations/prometheus_library/nginx_ingress.md#configuring-nginx-ingress-monitoring).

If you do not have Kubernetes or Prometheus installed, then Auto Review Apps,
Auto Deploy, and Auto Monitoring will be silently skipped.

One all requirements are met, you can go ahead and [enable Auto DevOps](#enablingdisabling-auto-devops).

## Auto DevOps base domain

The Auto DevOps base domain is required if you want to make use of
[Auto Review Apps](#auto-review-apps), [Auto Deploy](#auto-deploy), and
[Auto Monitoring](#auto-monitoring). It can be defined in any of the following
places:

- either under the cluster's settings, whether for [projects](../../user/project/clusters/index.md#base-domain) or [groups](../../user/group/clusters/index.md#base-domain)
- or in instance-wide settings in the **admin area > Settings** under the "Continuous Integration and Delivery" section
- or at the project level as a variable: `KUBE_INGRESS_BASE_DOMAIN`
- or at the group level as a variable: `KUBE_INGRESS_BASE_DOMAIN`.

The base domain variable `KUBE_INGRESS_BASE_DOMAIN` follows the same order of precedence
as other environment [variables](../../ci/variables/README.md#priority-of-environment-variables).

TIP: **Tip:**
If you're using the [GitLab managed app for Ingress](../../user/clusters/applications.md#ingress),
the URL endpoint should be automatically configured for you. All you have to do
is use its value for the `KUBE_INGRESS_BASE_DOMAIN` variable.

NOTE: **Note:**
`AUTO_DEVOPS_DOMAIN` was [deprecated in GitLab 11.8](https://gitlab.com/gitlab-org/gitlab-foss/issues/52363)
and replaced with `KUBE_INGRESS_BASE_DOMAIN`. It was removed in
[GitLab 12.0](https://gitlab.com/gitlab-org/gitlab-foss/issues/56959).

A wildcard DNS A record matching the base domain(s) is required, for example,
given a base domain of `example.com`, you'd need a DNS entry like:

```text
*.example.com   3600     A     1.2.3.4
```

In this case, `example.com` is the domain name under which the deployed apps will be served,
and `1.2.3.4` is the IP address of your load balancer; generally NGINX
([see requirements](#requirements)). How to set up the DNS record is beyond
the scope of this document; you should check with your DNS provider.

Alternatively you can use free public services like [nip.io](https://nip.io)
which provide automatic wildcard DNS without any configuration. Just set the
Auto DevOps base domain to `1.2.3.4.nip.io`.

Once set up, all requests will hit the load balancer, which in turn will route
them to the Kubernetes pods that run your application(s).

## Enabling/Disabling Auto DevOps

When first using Auto DevOps, review the [requirements](#requirements) to ensure all necessary components to make
full use of Auto DevOps are available. If this is your fist time, we recommend you follow the
[quick start guide](quick_start_guide.md).

GitLab.com users can enable/disable Auto DevOps at the project-level only. Self-managed users
can enable/disable Auto DevOps at the project-level, group-level or instance-level.

### At the project level

If enabling, check that your project doesn't have a `.gitlab-ci.yml`, or if one exists, remove it.

1. Go to your project's **Settings > CI/CD > Auto DevOps**.
1. Toggle the **Default to Auto DevOps pipeline** checkbox (checked to enable, unchecked to disable)
1. When enabling, it's optional but recommended to add in the [base domain](#auto-devops-base-domain)
   that will be used by Auto DevOps to [deploy your application](#auto-deploy)
   and choose the [deployment strategy](#deployment-strategy).
1. Click **Save changes** for the changes to take effect.

When the feature has been enabled, an Auto DevOps pipeline is triggered on the default branch.

### At the group level

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/52447) in GitLab 11.10.

Only administrators and group owners can enable or disable Auto DevOps at the group level.

To enable or disable Auto DevOps at the group-level:

1. Go to group's **Settings > CI/CD > Auto DevOps** page.
1. Toggle the **Default to Auto DevOps pipeline** checkbox (checked to enable, unchecked to disable).
1. Click **Save changes** button for the changes to take effect.

When enabling or disabling Auto DevOps at group-level, group configuration will be implicitly used for
the subgroups and projects inside that group, unless Auto DevOps is specifically enabled or disabled on
the subgroup or project.

### At the instance level (Administrators only)

Even when disabled at the instance level, group owners and project maintainers can still enable
Auto DevOps at the group and project level, respectively.

1. Go to **Admin area > Settings > Continuous Integration and Deployment**.
1. Toggle the checkbox labeled **Default to Auto DevOps pipeline for all projects**.
1. If enabling, optionally set up the Auto DevOps [base domain](#auto-devops-base-domain) which will be used for Auto Deploy and Auto Review Apps.
1. Click **Save changes** for the changes to take effect.

### Enable for a percentage of projects

There is also a feature flag to enable Auto DevOps by default to your chosen percentage of projects.

This can be enabled from the console with the following, which uses the example of 10%:

`Feature.get(:force_autodevops_on_by_default).enable_percentage_of_actors(10)`

### Deployment strategy

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/38542) in GitLab 11.0.

You can change the deployment strategy used by Auto DevOps by going to your
project's **Settings > CI/CD > Auto DevOps**.

The available options are:

- **Continuous deployment to production**: Enables [Auto Deploy](#auto-deploy)
  with `master` branch directly deployed to production.
- **Continuous deployment to production using timed incremental rollout**: Sets the
  [`INCREMENTAL_ROLLOUT_MODE`](#timed-incremental-rollout-to-production-premium) variable
  to `timed`, and production deployment will be executed with a 5 minute delay between
  each increment in rollout.
- **Automatic deployment to staging, manual deployment to production**: Sets the
  [`STAGING_ENABLED`](#deploy-policy-for-staging-and-production-environments) and
  [`INCREMENTAL_ROLLOUT_MODE`](#incremental-rollout-to-production-premium) variables
  to `1` and `manual`. This means:

  - `master` branch is directly deployed to staging.
  - Manual actions are provided for incremental rollout to production.

## Using multiple Kubernetes clusters **(PREMIUM)**

When using Auto DevOps, you may want to deploy different environments to
different Kubernetes clusters. This is possible due to the 1:1 connection that
[exists between them](../../user/project/clusters/index.md#multiple-kubernetes-clusters-premium).

In the [Auto DevOps template] (used behind the scenes by Auto DevOps), there
are currently 3 defined environment names that you need to know:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

Those environments are tied to jobs that use [Auto Deploy](#auto-deploy), so
except for the environment scope, they would also need to have a different
domain they would be deployed to. This is why you need to define a separate
`KUBE_INGRESS_BASE_DOMAIN` variable for all the above
[based on the environment](../../ci/variables/README.md#limiting-environment-scopes-of-environment-variables).

The following table is an example of how the three different clusters would
be configured.

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` variable value | Variable environment scope | Notes |
|--------------|---------------------------|-------------------------------------------|----------------------------|---|
| review       | `review/*`                | `review.example.com`                      | `review/*`                 | The review cluster which will run all [Review Apps](../../ci/review_apps/index.md). `*` is a wildcard, which means it will be used by every environment name starting with `review/`. |
| staging      | `staging`                 | `staging.example.com`                     | `staging`                  | (Optional) The staging cluster which will run the deployments of the staging environments. You need to [enable it first](#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                             | `production`               | The production cluster which will run the deployments of the production environment. You can use [incremental rollouts](#incremental-rollout-to-production-premium). |

To add a different cluster for each environment:

1. Navigate to your project's **Operations > Kubernetes** and create the Kubernetes clusters
   with their respective environment scope as described from the table above.

   ![Auto DevOps multiple clusters](img/autodevops_multiple_clusters.png)

1. After the clusters are created, navigate to each one and install Helm Tiller
   and Ingress. Wait for the Ingress IP address to be assigned.
1. Make sure you have [configured your DNS](#auto-devops-base-domain) with the
   specified Auto DevOps domains.
1. Navigate to each cluster's page, through **Operations > Kubernetes**,
   and add the domain based on its Ingress IP address.

Now that all is configured, you can test your setup by creating a merge request
and verifying that your app is deployed as a review app in the Kubernetes
cluster with the `review/*` environment scope. Similarly, you can check the
other environments.

## Stages of Auto DevOps

The following sections describe the stages of Auto DevOps. Read them carefully
to understand how each one works.

### Auto Build

Auto Build creates a build of the application using an existing `Dockerfile` or
Heroku buildpacks.

Either way, the resulting Docker image is automatically pushed to the
[Container Registry][container-registry] and tagged with the commit SHA or tag.

#### Auto Build using a Dockerfile

If a project's repository contains a `Dockerfile`, Auto Build will use
`docker build` to create a Docker image.

If you are also using Auto Review Apps and Auto Deploy and choose to provide
your own `Dockerfile`, make sure you expose your application to port
`5000` as this is the port assumed by the
[default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app). Alternatively you can override the default values by [customizing the Auto Deploy Helm chart](#custom-helm-chart)

#### Auto Build using Heroku buildpacks

Auto Build builds an application using a project's `Dockerfile` if present, or
otherwise it will use [Herokuish](https://github.com/gliderlabs/herokuish)
and [Heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks)
to automatically detect and build the application into a Docker image.

Each buildpack requires certain files to be in your project's repository for
Auto Build to successfully build your application. For example, the following
files are required at the root of your application's repository, depending on
the language:

- A `Pipfile` or `requirements.txt` file for Python projects.
- A `Gemfile` or `Gemfile.lock` file for Ruby projects.

For the requirements of other languages and frameworks, read the
[buildpacks docs](https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks).

TIP: **Tip:**
If Auto Build fails despite the project meeting the buildpack requirements, set
a project variable `TRACE=true` to enable verbose logging, which may help to
troubleshoot.

### Auto Test

Auto Test automatically runs the appropriate tests for your application using
[Herokuish](https://github.com/gliderlabs/herokuish) and [Heroku
buildpacks](https://devcenter.heroku.com/articles/buildpacks) by analyzing
your project to detect the language and framework. Several languages and
frameworks are detected automatically, but if your language is not detected,
you may succeed with a [custom buildpack](#custom-buildpacks). Check the
[currently supported languages](#currently-supported-languages).

Auto Test uses tests you already have in your application. If there are no
tests, it's up to you to add them.

### Auto Code Quality **(STARTER)**

Auto Code Quality uses the
[Code Quality image](https://gitlab.com/gitlab-org/security-products/codequality) to run
static analysis and other code checks on the current code. The report is
created, and is uploaded as an artifact which you can later download and check
out.

Any differences between the source and target branches are also
[shown in the merge request widget](../../user/project/merge_requests/code_quality.md).

### Auto SAST **(ULTIMATE)**

> Introduced in [GitLab Ultimate][ee] 10.3.

Static Application Security Testing (SAST) uses the
[SAST Docker image](https://gitlab.com/gitlab-org/security-products/sast) to run static
analysis on the current code and checks for potential security issues. The
Auto SAST stage will be skipped on licenses other than Ultimate and requires GitLab Runner 11.5 or above.

Once the report is created, it's uploaded as an artifact which you can later download and
check out.

Any security warnings are also shown in the merge request widget. Read more how
[SAST works](../../user/application_security/sast/index.md).

### Auto Dependency Scanning **(ULTIMATE)**

> Introduced in [GitLab Ultimate][ee] 10.7.

Dependency Scanning uses the
[Dependency Scanning Docker image](https://gitlab.com/gitlab-org/security-products/dependency-scanning)
to run analysis on the project dependencies and checks for potential security issues.
The Auto Dependency Scanning stage will be skipped on licenses other than Ultimate
and requires GitLab Runner 11.5 or above.

Once the
report is created, it's uploaded as an artifact which you can later download and
check out.

Any security warnings are also shown in the merge request widget. Read more about
[Dependency Scanning](../../user/application_security/dependency_scanning/index.md).

### Auto License Compliance **(ULTIMATE)**

> Introduced in [GitLab Ultimate][ee] 11.0.

License Compliance uses the
[License Compliance Docker image](https://gitlab.com/gitlab-org/security-products/license-management)
to search the project dependencies for their license. The Auto License Compliance stage
will be skipped on licenses other than Ultimate.

Once the
report is created, it's uploaded as an artifact which you can later download and
check out.

Any licenses are also shown in the merge request widget. Read more how
[License Compliance works](../../user/application_security/license_compliance/index.md).

### Auto Container Scanning **(ULTIMATE)**

> Introduced in GitLab 10.4.

Vulnerability Static Analysis for containers uses
[Clair](https://github.com/coreos/clair) to run static analysis on a
Docker image and checks for potential security issues. The Auto Container Scanning stage
will be skipped on licenses other than Ultimate.

Once the report is
created, it's uploaded as an artifact which you can later download and
check out.

Any security warnings are also shown in the merge request widget. Read more how
[Container Scanning works](../../user/application_security/container_scanning/index.md).

### Auto Review Apps

This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [requirements](#requirements) are not met, the job will
silently be skipped.

[Review Apps][review-app] are temporary application environments based on the
branch's code so developers, designers, QA, product managers, and other
reviewers can actually see and interact with code changes as part of the review
process. Auto Review Apps create a Review App for each branch.

Auto Review Apps will deploy your app to your Kubernetes cluster only. When no cluster
is available, no deployment will occur.

The Review App will have a unique URL based on the project ID, the branch or tag
name, and a unique number, combined with the Auto DevOps base domain. For
example, `13083-review-project-branch-123456.example.com`. A link to the Review App shows
up in the merge request widget for easy discovery. When the branch or tag is deleted,
for example after the merge request is merged, the Review App will automatically
be deleted.

Review apps are deployed using the
[auto-deploy-app](https://gitlab.com/gitlab-org/charts/auto-deploy-app) chart with
Helm, which can be [customized](#custom-helm-chart). The app will be deployed into the [Kubernetes
namespace](../../user/project/clusters/index.md#deployment-variables)
for the environment.

Since GitLab 11.4, a [local
Tiller](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

### Auto DAST **(ULTIMATE)**

> Introduced in [GitLab Ultimate][ee] 10.4.

This is an optional step, since it requires a [review app](#auto-review-apps).
If that requirement is not met, the job will be silently skipped.

Dynamic Application Security Testing (DAST) uses the
popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on the current code and checks for potential security
issues. The Auto DAST stage will be skipped on licenses other than Ultimate.

Once the report is created, it's uploaded as an artifact which you can
later download and check out.

Any security warnings are also shown in the merge request widget. Read how
[DAST works](../../user/application_security/dast/index.md).

On your default branch, DAST scans an app deployed specifically for that purpose.
The app is deleted after DAST has run.

On feature branches, DAST scans the [review app](#auto-review-apps).

#### Overriding the DAST target

To use a custom target instead of the auto-deployed review apps,
set a `DAST_WEBSITE` environment variable to the URL for DAST to scan.

NOTE: **Note:**
If [DAST Full Scan](../../user/application_security/dast/index.md#full-scan) is enabled, it is strongly advised **not**
to set `DAST_WEBSITE` to any staging or production environment. DAST Full Scan
actively attacks the target, which can take down the application and lead to
data loss or corruption.

#### Disabling Auto DAST

DAST can be disabled:

- On all branches by setting the `DAST_DISABLED` environment variable to `"true"`.
- Only on the default branch by setting the `DAST_DISABLED_FOR_DEFAULT_BRANCH` environment variable to `"true"`.

### Auto Browser Performance Testing **(PREMIUM)**

> Introduced in [GitLab Premium][ee] 10.4.

Auto Browser Performance Testing utilizes the [Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/) to measure the performance of a web page. A JSON report is created and uploaded as an artifact, which includes the overall performance score for each page. By default, the root page of Review and Production environments will be tested. If you would like to add additional URL's to test, simply add the paths to a file named `.gitlab-urls.txt` in the root directory, one per line. For example:

```text
/
/features
/direction
```

Any performance differences between the source and target branches are also
[shown in the merge request widget](../../user/project/merge_requests/browser_performance_testing.md).

### Auto Deploy

This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [requirements](#requirements) are not met, the job will
silently be skipped.

After a branch or merge request is merged into the project's default branch (usually
`master`), Auto Deploy deploys the application to a `production` environment in
the Kubernetes cluster, with a namespace based on the project name and unique
project ID, for example `project-4321`.

Auto Deploy doesn't include deployments to staging or canary by default, but the
[Auto DevOps template] contains job definitions for these tasks if you want to
enable them.

You can make use of [environment variables](#environment-variables) to automatically
scale your pod replicas and to apply custom arguments to the Auto DevOps `helm upgrade` commands. This is an easy way to [customize the Auto Deploy Helm chart](#custom-helm-chart).

Apps are deployed using the
[auto-deploy-app](https://gitlab.com/gitlab-org/charts/auto-deploy-app) chart with
Helm. The app will be deployed into the [Kubernetes
namespace](../../user/project/clusters/index.md#deployment-variables)
for the environment.

Since GitLab 11.4, a [local
Tiller](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

> [Introduced][ce-19507] in GitLab 11.0.

For internal and private projects a [GitLab Deploy Token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token)
will be automatically created, when Auto DevOps is enabled and the Auto DevOps settings are saved. This Deploy Token
can be used for permanent access to the registry. When the GitLab Deploy Token has been manually revoked, it won't be automatically created.

If the GitLab Deploy Token cannot be found, `CI_REGISTRY_PASSWORD` is
used. Note that `CI_REGISTRY_PASSWORD` is only valid during deployment.
This means that Kubernetes will be able to successfully pull the
container image during deployment but in cases where the image needs to
be pulled again, e.g. after pod eviction, Kubernetes will fail to do so
as it will be attempting to fetch the image using
`CI_REGISTRY_PASSWORD`.

#### Migrations

> [Introduced][ce-21955] in GitLab 11.4

Database initialization and migrations for PostgreSQL can be configured to run
within the application pod by setting the project variables `DB_INITIALIZE` and
`DB_MIGRATE` respectively.

If present, `DB_INITIALIZE` will be run as a shell command within an
application pod as a Helm post-install hook. As some applications will
not run without a successful database initialization step, GitLab will
deploy the first release without the application deployment and only the
database initialization step. After the database initialization completes,
GitLab will deploy a second release with the application deployment as
normal.

Note that a post-install hook means that if any deploy succeeds,
`DB_INITIALIZE` will not be processed thereafter.

If present, `DB_MIGRATE` will be run as a shell command within an application pod as
a Helm pre-upgrade hook.

For example, in a Rails application in an image built with
[Herokuish](https://github.com/gliderlabs/herokuish):

- `DB_INITIALIZE` can be set to `RAILS_ENV=production /bin/herokuish procfile exec bin/rails db:setup`
- `DB_MIGRATE` can be set to `RAILS_ENV=production /bin/herokuish procfile exec bin/rails db:migrate`

Unless you have a `Dockerfile` in your repo, your image is built with
Herokuish, and you must prefix commands run in these images with `/bin/herokuish
procfile exec` to replicate the environment where your application will run.

#### Workers

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/30628) in GitLab 12.6, `.gitlab/auto-deploy-values.yaml` will be used by default for Helm upgrades.

Some web applications need to run extra deployments for "worker processes". For
example, it is common in a Rails application to have a separate worker process
to run background tasks like sending emails.

The [default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app)
used in Auto Deploy [has support for running worker
processes](https://gitlab.com/gitlab-org/charts/auto-deploy-app/merge_requests/9).

In order to run a worker, you'll need to ensure that it is able to respond to
the standard health checks, which expect a successful HTTP response on port
`5000`. For [Sidekiq](https://github.com/mperham/sidekiq), you could make use of
the [`sidekiq_alive` gem](https://rubygems.org/gems/sidekiq_alive) to do this.

In order to work with Sidekiq, you'll also need to ensure your deployments have
access to a Redis instance. Auto DevOps won't deploy this for you so you'll
need to:

- Maintain your own Redis instance.
- Set a CI variable `K8S_SECRET_REDIS_URL`, which the URL of this instance to
  ensure it's passed into your deployments.

Once you have configured your worker to respond to health checks, run a Sidekiq
worker for your Rails application. For:

- GitLab 12.6 and later, either:
  - Add a file named `.gitlab/auto-deploy-values.yaml` to your repository. It will
    be automatically used if found.
  - Add a file with a different name or path to the repository, and override the value of the
    `HELM_UPGRADE_VALUES_FILE` variable with the path and name.
- GitLab 12.5 and earlier, run the worker with the `--values` parameter that specifies
  a file in the repository.

In any case, the file must contain the following:

```yml
workers:
  sidekiq:
    replicaCount: 1
    command:
    - /bin/herokuish
    - procfile
    - exec
    - sidekiq
    preStopCommand:
    - /bin/herokuish
    - procfile
    - exec
    - sidekiqctl
    - quiet
    terminationGracePeriodSeconds: 60
```

#### Running commands in the container

Applications built with [Auto Build](#auto-build) using Herokuish, the default
unless you have [a custom Dockerfile](#auto-build-using-a-dockerfile), may require
commands to be wrapped as follows:

```shell
/bin/herokuish procfile exec $COMMAND
```

This might be neccessary, for example, when:

- Attaching using `kubectl exec`.
- Using GitLab's [Web Terminal](../../ci/environments.md#web-terminals).

For example, to start a Rails console from the application root directory, run:

```sh
/bin/herokuish procfile exec bin/rails c
```

### Auto Monitoring

Once your application is deployed, Auto Monitoring makes it possible to monitor
your application's server and response metrics right out of the box. Auto
Monitoring uses [Prometheus](../../user/project/integrations/prometheus.md) to
get system metrics such as CPU and memory usage directly from
[Kubernetes](../../user/project/integrations/prometheus_library/kubernetes.md),
and response metrics such as HTTP error rates, latency, and throughput from the
[NGINX server](../../user/project/integrations/prometheus_library/nginx_ingress.md).

The metrics include:

- **Response Metrics:** latency, throughput, error rate
- **System Metrics:** CPU utilization, memory utilization

To make use of Auto Monitoring:

1. [Install and configure the requirements](#requirements).
1. [Enable Auto DevOps](#enablingdisabling-auto-devops) if you haven't done already.
1. Finally, go to your project's **CI/CD > Pipelines** and run a pipeline.
1. Once the pipeline finishes successfully, open the
   [monitoring dashboard for a deployed environment](../../ci/environments.md#monitoring-environments)
   to view the metrics of your deployed application. To view the metrics of the
   whole Kubernetes cluster, navigate to **Operations > Metrics**.

![Auto Metrics](img/auto_monitoring.png)

## Customizing

While Auto DevOps provides great defaults to get you started, you can customize
almost everything to fit your needs; from custom [buildpacks](#custom-buildpacks),
to [`Dockerfile`s](#custom-dockerfile), [Helm charts](#custom-helm-chart), or
even copying the complete [CI/CD configuration](#customizing-gitlab-ciyml)
into your project to enable staging and canary deployments, and more.

### Custom buildpacks

If the automatic buildpack detection fails for your project, or if you want to
use a custom buildpack, you can override the buildpack(s) using a project variable
or a `.buildpacks` file in your project:

- **Project variable** - Create a project variable `BUILDPACK_URL` with the URL
  of the buildpack to use.
- **`.buildpacks` file** - Add a file in your project's repo called  `.buildpacks`
  and add the URL of the buildpack to use on a line in the file. If you want to
  use multiple buildpacks, you can enter them in, one on each line.

#### Multiple buildpacks

Using multiple buildpacks isn't fully supported by Auto DevOps because, when using the `.buildpacks`
file, Auto Test will not work.

The buildpack [heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/),
which is used under the hood to parse the `.buildpacks` file, doesn't provide the necessary commands
`bin/test-compile` and `bin/test`.

If your goal is to use only a single custom buildpack, you should provide the project variable
`BUILDPACK_URL` instead.

### Custom `Dockerfile`

If your project has a `Dockerfile` in the root of the project repo, Auto DevOps
will build a Docker image based on the Dockerfile rather than using buildpacks.
This can be much faster and result in smaller images, especially if your
Dockerfile is based on [Alpine](https://hub.docker.com/_/alpine/).

### Passing arguments to `docker build`

Arguments can be passed to the `docker build` command using the
`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` project variable.

For example, to build a Docker image based on based on the `ruby:alpine`
instead of the default `ruby:latest`:

1. Set `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` to `--build-arg=RUBY_VERSION=alpine`.
1. Add the following to a custom `Dockerfile`:

    ```docker
    ARG RUBY_VERSION=latest
    FROM ruby:$RUBY_VERSION

    # ... put your stuff here
    ```

NOTE: **Note:**
Passing in complex values (newlines and spaces, for example) will likely
cause escaping issues due to the way this argument is used in Auto DevOps.
Consider using Base64 encoding of such values to avoid this problem.

CAUTION: **Warning:**
Avoid passing secrets as Docker build arguments if possible, as they may be
persisted in your image. See
[this discussion](https://github.com/moby/moby/issues/13490) for details.

### Passing secrets to `docker build`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/25514) in GitLab 12.3, but available in versions 11.9 and above.

CI environment variables can be passed as [build
secrets](https://docs.docker.com/develop/develop-images/build_enhancements/#new-docker-build-secret-information) to the `docker build` command by listing them comma separated by name in the
`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` variable. For example, in order to forward the variables `CI_COMMIT_SHA` and `CI_ENVIRONMENT_NAME`, one would set `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` to `CI_COMMIT_SHA,CI_ENVIRONMENT_NAME`.

Unlike build arguments, these are not persisted by Docker in the final image
(though you can still persist them yourself, so **be careful**).

In projects:

- Without a `Dockerfile`, these are available automatically as environment
  variables.
- With a `Dockerfile`, the following is required:

  1. Activate the experimental `Dockerfile` syntax by adding the following
     to the top of the file:

     ```docker
     # syntax = docker/dockerfile:experimental
     ```

  1. To make secrets available in any `RUN $COMMAND` in the `Dockerfile`, mount
     the secret file and source it prior to running `$COMMAND`:

     ```docker
     RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
     ```

NOTE: **Note:**
When `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` is set, Auto DevOps
enables the experimental [Docker BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/)
feature to use the `--secret` flag.

### Custom Helm Chart

Auto DevOps uses [Helm](https://helm.sh/) to deploy your application to Kubernetes.
You can override the Helm chart used by bundling up a chart into your project
repo or by specifying a project variable:

- **Bundled chart** - If your project has a `./chart` directory with a `Chart.yaml`
  file in it, Auto DevOps will detect the chart and use it instead of the [default
  one](https://gitlab.com/gitlab-org/charts/auto-deploy-app).
  This can be a great way to control exactly how your application is deployed.
- **Project variable** - Create a [project variable](../../ci/variables/README.md#gitlab-cicd-environment-variables)
  `AUTO_DEVOPS_CHART` with the URL of a custom chart to use or create two project variables `AUTO_DEVOPS_CHART_REPOSITORY` with the URL of a custom chart repository and `AUTO_DEVOPS_CHART` with the path to the chart.

You can also make use of the `HELM_UPGRADE_EXTRA_ARGS` environment variable to override the default values in the `values.yaml` file in the [default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app).
To apply your own `values.yaml` file to all Helm upgrade commands in Auto Deploy set `HELM_UPGRADE_EXTRA_ARGS` to `--values my-values.yaml`.

### Custom Helm chart per environment

You can specify the use of a custom Helm chart per environment by scoping the environment variable
to the desired environment. See [Limiting environment scopes of variables](../../ci/variables/README.md#limiting-environment-scopes-of-environment-variables).

### Customizing `.gitlab-ci.yml`

Auto DevOps is completely customizable because the [Auto DevOps template]:

- Is just an implementation of a [`.gitlab-ci.yml`](../../ci/yaml/README.md) file.
- Uses only features available to any implementation of `.gitlab-ci.yml`.

If you want to modify the CI/CD pipeline used by Auto DevOps, you can [`include`
the template](../../ci/yaml/README.md#includetemplate) and customize as
needed. To do this, add a `.gitlab-ci.yml` file to the root of your repository
containing the following:

```yml
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Then add any extra changes you want. Your additions will be merged with the
[Auto DevOps template] using the behaviour described for
[`include`](../../ci/yaml/README.md#include).

It is also possible to copy and paste the contents of the [Auto DevOps
template] into your project and edit this as needed. You may prefer to do it
that way if you want to specifically remove any part of it.

### Using components of Auto DevOps

If you only require a subset of the features offered by Auto DevOps, you can include
individual Auto DevOps jobs into your own `.gitlab-ci.yml`. Each component job relies
on a stage that should be defined in the `.gitlab-ci.yml` that includes the template.

For example, to make use of [Auto Build](#auto-build), you can add the following to
your `.gitlab-ci.yml`:

```yaml
stages:
  - build

include:
  - template: Jobs/Build.gitlab-ci.yml
```

Consult the [Auto DevOps template] for information on available jobs.

### PostgreSQL database support

In order to support applications that require a database,
[PostgreSQL][postgresql] is provisioned by default. The credentials to access
the database are preconfigured, but can be customized by setting the associated
[variables](#environment-variables). These credentials can be used for defining a
`DATABASE_URL` of the format:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

#### Using external PostgreSQL database providers

While Auto DevOps provides out-of-the-box support for a PostgreSQL container for
production environments, for some use-cases it may not be sufficiently secure or
resilient and you may wish to use an external managed provider for PostgreSQL.
For example, AWS Relational Database Service.

You will need to define environment-scoped variables for `POSTGRES_ENABLED` and `DATABASE_URL` in your project's CI/CD settings.

To achieve this:

1. Disable the built-in PostgreSQL installation for the required environments using
   scoped [environment variables](../../ci/environments.md#scoping-environments-with-specs).
   For this use case, it's likely that only `production` will need to be added to this
   list as the builtin PostgreSQL setup for Review Apps and staging will be sufficient
   as a high availability setup is not required.

   ![Auto Metrics](img/disable_postgres.png)

1. Define the `DATABASE_URL` CI variable as a scoped environment variable that will be
   available to your application. This should be a URL in the following format:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

You will need to ensure that your Kubernetes cluster has network access to wherever
PostgreSQL is hosted.

### Environment variables

The following variables can be used for setting up the Auto DevOps domain,
providing a custom Helm chart, or scaling your application. PostgreSQL can
also be customized, and you can easily use a [custom buildpack](#custom-buildpacks).

#### Build and deployment

The following table lists variables related to building and deploying
applications.

| **Variable**                            | **Description**                    |
|-----------------------------------------|------------------------------------|
| `ADDITIONAL_HOSTS`                      | Fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. |
| `<ENVIRONMENT>_ADDITIONAL_HOSTS`        | For a specific environment, the fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. This takes precedence over `ADDITIONAL_HOSTS`. |
| `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`    | Extra arguments to be passed to the `docker build` command. Note that using quotes will not prevent word splitting. [More details](#passing-arguments-to-docker-build). |
| `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` | A [comma-separated list of CI variable names](#passing-secrets-to-docker-build) to be passed to the `docker build` command as secrets. |
| `AUTO_DEVOPS_CHART`                     | Helm Chart used to deploy your apps. Defaults to the one [provided by GitLab](https://gitlab.com/gitlab-org/charts/auto-deploy-app). |
| `AUTO_DEVOPS_CHART_REPOSITORY`          | Helm Chart repository used to search for charts. Defaults to `https://charts.gitlab.io`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_NAME`     | From GitLab 11.11, used to set the name of the Helm repository. Defaults to `gitlab`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME` | From GitLab 11.11, used to set a username to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD` | From GitLab 11.11, used to set a password to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME`. |
| `AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE` | From GitLab 12.5, used in combination with [Modsecurity feature flag](../../user/clusters/applications.md#web-application-firewall-modsecurity) to toggle [Modsecurity's `SecRuleEngine`](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine) behavior. Defaults to `DetectionOnly`. |
| `BUILDPACK_URL`                         | Buildpack's full URL. Can point to either Git repositories or a tarball URL. For Git repositories, it is possible to point to a specific `ref`. For example `https://github.com/heroku/heroku-buildpack-ruby.git#v142`. |
| `CANARY_ENABLED`                        | From GitLab 11.0, used to define a [deploy policy for canary environments](#deploy-policy-for-canary-environments-premium). |
| `CANARY_PRODUCTION_REPLICAS`            | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md) in the production environment. Takes precedence over `CANARY_REPLICAS`. Defaults to 1. |
| `CANARY_REPLICAS`                       | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md). Defaults to 1. |
| `HELM_RELEASE_NAME`                     | From GitLab 12.1, allows the `helm` release name to be overridden. Can be used to assign unique release names when deploying multiple projects to a single namespace. |
| `HELM_UPGRADE_VALUES_FILE`              | From GitLab 12.6, allows the `helm upgrade` values file to be overridden. Defaults to `.gitlab/auto-deploy-values.yaml`. |
| `HELM_UPGRADE_EXTRA_ARGS`               | From GitLab 11.11, allows extra arguments in `helm` commands when deploying the application. Note that using quotes will not prevent word splitting. **Tip:** you can use this variable to [customize the Auto Deploy Helm chart](#custom-helm-chart) by applying custom override values with `--values my-values.yaml`. |
| `INCREMENTAL_ROLLOUT_MODE`              | From GitLab 11.4, if present, can be used to enable an [incremental rollout](#incremental-rollout-to-production-premium) of your application for the production environment. Set to `manual` for manual deployment jobs or `timed` for automatic rollout deployments with a 5 minute delay each one. |
| `K8S_SECRET_*`                          | From GitLab 11.7, any variable prefixed with [`K8S_SECRET_`](#application-secret-variables) will be made available by Auto DevOps as environment variables to the deployed application. |
| `KUBE_INGRESS_BASE_DOMAIN`              | From GitLab 11.8, can be used to set a domain per cluster. See [cluster domains](../../user/project/clusters/index.md#base-domain) for more information. |
| `PRODUCTION_REPLICAS`                   | Number of replicas to deploy in the production environment. Takes precedence over `REPLICAS` and defaults to 1. For zero downtime upgrades, set to 2 or greater. |
| `REPLICAS`                              | Number of replicas to deploy. Defaults to 1. |
| `ROLLOUT_RESOURCE_TYPE`                 | From GitLab 11.9, allows specification of the resource type being deployed when using a custom Helm chart. Default value is `deployment`. |
| `ROLLOUT_STATUS_DISABLED`               | From GitLab 12.0, used to disable rollout status check because it doesn't support all resource types, for example, `cronjob`. |
| `STAGING_ENABLED`                       | From GitLab 10.8, used to define a [deploy policy for staging and production environments](#deploy-policy-for-staging-and-production-environments). |

TIP: **Tip:**
Set up the replica variables using a
[project variable](../../ci/variables/README.md#gitlab-cicd-environment-variables)
and scale your application by just redeploying it!

CAUTION: **Caution:**
You should *not* scale your application using Kubernetes directly. This can
cause confusion with Helm not detecting the change, and subsequent deploys with
Auto DevOps can undo your changes.

#### Database

The following table lists variables related to the database.

| **Variable**                            | **Description**                    |
| `DB_INITIALIZE`                         | From GitLab 11.4, used to specify the command to run to initialize the application's PostgreSQL database. Runs inside the application pod. |
| `DB_MIGRATE`                            | From GitLab 11.4, used to specify the command to run to migrate the application's PostgreSQL database. Runs inside the application pod. |
| `POSTGRES_ENABLED`                      | Whether PostgreSQL is enabled. Defaults to `"true"`. Set to `false` to disable the automatic deployment of PostgreSQL. |
| `POSTGRES_USER`                         | The PostgreSQL user. Defaults to `user`. Set it to use a custom username. |
| `POSTGRES_PASSWORD`                     | The PostgreSQL password. Defaults to `testing-password`. Set it to use a custom password. |
| `POSTGRES_DB`                           | The PostgreSQL database name. Defaults to the value of [`$CI_ENVIRONMENT_SLUG`](../../ci/variables/README.md#predefined-environment-variables). Set it to use a custom database name. |
| `POSTGRES_VERSION`                      | Tag for the [`postgres` Docker image](https://hub.docker.com/_/postgres) to use. Defaults to `9.6.2`. |

#### Security tools

The following table lists variables related to security tools.

| **Variable**                            | **Description**                    |
| `SAST_CONFIDENCE_LEVEL`                 | Minimum confidence level of security issues you want to be reported; `1` for Low, `2` for Medium, `3` for High. Defaults to `3`. |

#### Disable jobs

The following table lists variables used to disable jobs.

| **Variable**                            | **Description**                    |
| `CODE_QUALITY_DISABLED`                 | From GitLab 11.0, used to disable the `codequality` job. If the variable is present, the job will not be created. |
| `CONTAINER_SCANNING_DISABLED`           | From GitLab 11.0, used to disable the `sast:container` job. If the variable is present, the job will not be created. |
| `DAST_DISABLED`                         | From GitLab 11.0, used to disable the `dast` job. If the variable is present, the job will not be created. |
| `DEPENDENCY_SCANNING_DISABLED`          | From GitLab 11.0, used to disable the `dependency_scanning` job. If the variable is present, the job will not be created. |
| `LICENSE_MANAGEMENT_DISABLED`           | From GitLab 11.0, used to disable the `license_management` job. If the variable is present, the job will not be created. |
| `PERFORMANCE_DISABLED`                  | From GitLab 11.0, used to disable the `performance` job. If the variable is present, the job will not be created. |
| `REVIEW_DISABLED`                       | From GitLab 11.0, used to disable the `review` and the manual `review:stop` job. If the variable is present, these jobs will not be created. |
| `SAST_DISABLED`                         | From GitLab 11.0, used to disable the `sast` job. If the variable is present, the job will not be created. |
| `TEST_DISABLED`                         | From GitLab 11.0, used to disable the `test` job. If the variable is present, the job will not be created. |

#### Application secret variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/49056) in GitLab 11.7.

Some applications need to define secret variables that are
accessible by the deployed application. Auto DevOps detects variables where the key starts with
`K8S_SECRET_` and make these prefixed variables available to the
deployed application, as environment variables.

To configure your application variables:

1. Go to your project's **Settings > CI/CD**, then expand the section
   called **Variables**.

1. Create a CI Variable, ensuring the key is prefixed with
   `K8S_SECRET_`. For example, you can create a variable with key
   `K8S_SECRET_RAILS_MASTER_KEY`.

1. Run an Auto Devops pipeline either by manually creating a new
   pipeline or by pushing a code change to GitLab.

Auto DevOps pipelines will take your application secret variables to
populate a Kubernetes secret. This secret is unique per environment.
When deploying your application, the secret is loaded as environment
variables in the container running the application. Following the
example above, you can see the secret below containing the
`RAILS_MASTER_KEY` variable.

```sh
$ kubectl get secret production-secret -n minimal-ruby-app-54 -o yaml
apiVersion: v1
data:
  RAILS_MASTER_KEY: MTIzNC10ZXN0
kind: Secret
metadata:
  creationTimestamp: 2018-12-20T01:48:26Z
  name: production-secret
  namespace: minimal-ruby-app-54
  resourceVersion: "429422"
  selfLink: /api/v1/namespaces/minimal-ruby-app-54/secrets/production-secret
  uid: 57ac2bfd-03f9-11e9-b812-42010a9400e4
type: Opaque
```

Environment variables are generally considered immutable in a Kubernetes
pod. Therefore, if you update an application secret without changing any
code then manually create a new pipeline, you will find that any running
application pods will not have the updated secrets. In this case, you
can either push a code update to GitLab to force the Kubernetes
Deployment to recreate pods or manually delete running pods to
cause Kubernetes to create new pods with updated secrets.

NOTE: **Note:**
Variables with multiline values are not currently supported due to
limitations with the current Auto DevOps scripting environment.

#### Advanced replica variables setup

Apart from the two replica-related variables for production mentioned above,
you can also use others for different environments.

There's a very specific mapping between Kubernetes' label named `track`,
GitLab CI/CD environment names, and the replicas environment variable.
The general rule is: `TRACK_ENV_REPLICAS`. Where:

- `TRACK`: The capitalized value of the `track`
  [Kubernetes label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
  in the Helm Chart app definition. If not set, it will not be taken into account
  to the variable name.
- `ENV`: The capitalized environment name of the deploy job that is set in
  `.gitlab-ci.yml`.

That way, you can define your own `TRACK_ENV_REPLICAS` variables with which
you will be able to scale the pod's replicas easily.

In the example below, the environment's name is `qa` and it deploys the track
`foo` which would result in looking for the `FOO_QA_REPLICAS` environment
variable:

```yaml
QA testing:
  stage: deploy
  environment:
    name: qa
  script:
  - deploy foo
```

The track `foo` being referenced would also need to be defined in the
application's Helm chart, like:

```yaml
replicaCount: 1
image:
  repository: gitlab.example.com/group/project
  tag: stable
  pullPolicy: Always
  secrets:
    - name: gitlab-registry
application:
  track: foo
  tier: web
service:
  enabled: true
  name: web
  type: ClusterIP
  url: http://my.host.com/
  externalPort: 5000
  internalPort: 5000
```

#### Deploy policy for staging and production environments

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ci-yml/merge_requests/160)
in GitLab 10.8.

TIP: **Tip:**
You can also set this inside your [project's settings](#deployment-strategy).

The normal behavior of Auto DevOps is to use Continuous Deployment, pushing
automatically to the `production` environment every time a new pipeline is run
on the default branch. However, there are cases where you might want to use a
staging environment and deploy to production manually. For this scenario, the
`STAGING_ENABLED` environment variable was introduced.

If `STAGING_ENABLED` is defined in your project (e.g., set `STAGING_ENABLED` to
`1` as a CI/CD variable), then the application will be automatically deployed
to a `staging` environment, and a  `production_manual` job will be created for
you when you're ready to manually deploy to production.

#### Deploy policy for canary environments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ci-yml/merge_requests/171)
in GitLab 11.0.

A [canary environment](../../user/project/canary_deployments.md) can be used
before any changes are deployed to production.

If `CANARY_ENABLED` is defined in your project (e.g., set `CANARY_ENABLED` to
`1` as a CI/CD variable) then two manual jobs will be created:

- `canary` which will deploy the application to the canary environment
- `production_manual` which is to be used by you when you're ready to manually
  deploy to production.

#### Incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/5415) in GitLab 10.8.

TIP: **Tip:**
You can also set this inside your [project's settings](#deployment-strategy).

When you have a new version of your app to deploy in production, you may want
to use an incremental rollout to replace just a few pods with the latest code.
This will allow you to first check how the app is behaving, and later manually
increasing the rollout up to 100%.

If `INCREMENTAL_ROLLOUT_MODE` is set to `manual` in your project, then instead
of the standard `production` job, 4 different
[manual jobs](../../ci/pipelines.md#manual-actions-from-pipeline-graphs)
will be created:

1. `rollout 10%`
1. `rollout 25%`
1. `rollout 50%`
1. `rollout 100%`

The percentage is based on the `REPLICAS` variable and defines the number of
pods you want to have for your deployment. If you say `10`, and then you run
the `10%` rollout job, there will be `1` new pod + `9` old ones.

To start a job, click on the play icon next to the job's name. You are not
required to go from `10%` to `100%`, you can jump to whatever job you want.
You can also scale down by running a lower percentage job, just before hitting
`100%`. Once you get to `100%`, you cannot scale down, and you'd have to roll
back by redeploying the old version using the
[rollback button](../../ci/environments.md#retrying-and-rolling-back) in the
environment page.

Below, you can see how the pipeline will look if the rollout or staging
variables are defined.

Without `INCREMENTAL_ROLLOUT_MODE` and without `STAGING_ENABLED`:

![Staging and rollout disabled](img/rollout_staging_disabled.png)

Without `INCREMENTAL_ROLLOUT_MODE` and with `STAGING_ENABLED`:

![Staging enabled](img/staging_enabled.png)

With `INCREMENTAL_ROLLOUT_MODE` set to `manual` and without `STAGING_ENABLED`:

![Rollout enabled](img/rollout_enabled.png)

With `INCREMENTAL_ROLLOUT_MODE` set to `manual` and with `STAGING_ENABLED`

![Rollout and staging enabled](img/rollout_staging_enabled.png)

CAUTION: **Caution:**
Before GitLab 11.4 this feature was enabled by the presence of the
`INCREMENTAL_ROLLOUT_ENABLED` environment variable.
This configuration is deprecated and will be removed in the future.

#### Timed incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/7545) in GitLab 11.4.

TIP: **Tip:**
You can also set this inside your [project's settings](#deployment-strategy).

This configuration is based on
[incremental rollout to production](#incremental-rollout-to-production-premium).

Everything behaves the same way, except:

- It's enabled by setting the `INCREMENTAL_ROLLOUT_MODE` variable to `timed`.
- Instead of the standard `production` job, the following jobs are created with a 5 minute delay between each :
  1. `timed rollout 10%`
  1. `timed rollout 25%`
  1. `timed rollout 50%`
  1. `timed rollout 100%`

## Currently supported languages

Note that not all buildpacks support Auto Test yet, as it's a relatively new
enhancement. All of Heroku's [officially supported
languages](https://devcenter.heroku.com/articles/heroku-ci#currently-supported-languages)
support it, and some third-party buildpacks as well e.g., Go, Node, Java, PHP,
Python, Ruby, Gradle, Scala, and Elixir all support Auto Test, but notably the
multi-buildpack does not.

As of GitLab 10.0, the supported buildpacks are:

```text
- heroku-buildpack-multi     v1.0.0
- heroku-buildpack-ruby      v168
- heroku-buildpack-nodejs    v99
- heroku-buildpack-clojure   v77
- heroku-buildpack-python    v99
- heroku-buildpack-java      v53
- heroku-buildpack-gradle    v23
- heroku-buildpack-scala     v78
- heroku-buildpack-play      v26
- heroku-buildpack-php       v122
- heroku-buildpack-go        v72
- heroku-buildpack-erlang    fa17af9
- buildpack-nginx            v8
```

## Limitations

The following restrictions apply.

### Private registry support

There is no documented way of using private container registry with Auto DevOps.
We strongly advise using GitLab Container Registry with Auto DevOps in order to
simplify configuration and prevent any unforeseen issues.

### Installing Helm behind a proxy

GitLab does not yet support installing [Helm as a GitLab-managed App](../../user/clusters/applications.md#helm) when
behind a proxy. Users who wish to do so must inject their proxy settings
into the installation pods at runtime, for example by using a
[`PodPreset`](https://kubernetes.io/docs/concepts/workloads/pods/podpreset/):

```yml
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

- Auto Build and Auto Test may fail in detecting your language/framework. There
  may be no buildpack for your application, or your application may be missing the
  key files the buildpack is looking for. For example, for ruby apps, you must
  have a `Gemfile` to be properly detected, even though it is possible to write a
  Ruby app without a `Gemfile`. Try specifying a [custom
  buildpack](#custom-buildpacks).
- Auto Test may fail because of a mismatch between testing frameworks. In this
  case, you may need to customize your `.gitlab-ci.yml` with your test commands.
- Auto Deploy will fail if GitLab can not create a Kubernetes namespace and
  service account for your project. For help debugging this issue, see
  [Troubleshooting failed deployment jobs](../../user/project/clusters/index.md#troubleshooting).

### Auto DevOps banner

The following Auto DevOps banner will show for maintainers+ on new projects when Auto DevOps is not enabled

![Auto DevOps banner](img/autodevops_banner_v12_6.png)

The banner can be disabled:

- Per user when they dismiss it.
- Project-wide by explicitly [disabling Auto DevOps](#enablingdisabling-auto-devops).
- By a GitLab administrator for an entire GitLab instance by either:
  - Running the following in a Rails console:

    ```ruby
    Feature.get(:auto_devops_banner_disabled).enable
    ```

  - Through the REST API with an admin access token:

    ```sh
    curl --data "value=true" --header "PRIVATE-TOKEN: personal_access_token" https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled
    ```

[ce-37115]: https://gitlab.com/gitlab-org/gitlab-foss/issues/37115
[docker-in-docker]: ../../docker/using_docker_build.md#use-docker-in-docker-executor
[review-app]: ../../ci/review_apps/index.md
[container-registry]: ../../user/packages/container_registry/index.md
[postgresql]: https://www.postgresql.org/
[Auto DevOps template]: https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml
[ee]: https://about.gitlab.com/pricing/
[ce-21955]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/21955
[ce-19507]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/19507

## Development guides

[Development guide for Auto DevOps](../../development/auto_devops.md)
