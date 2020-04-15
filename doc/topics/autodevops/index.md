# Auto DevOps

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/37115) in GitLab 10.0.
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/41729) in GitLab 11.3.

Auto DevOps is enabled by default for all projects and will attempt to run on all pipelines
in each project. This default can be enabled or disabled by an instance administrator in the
[Auto DevOps settings](../../user/admin_area/settings/continuous_integration.md#auto-devops-core-only).
It will be automatically disabled in individual projects on their first pipeline failure,
if it has not been explicitly enabled for the project.

Since [GitLab 12.7](https://gitlab.com/gitlab-org/gitlab/issues/26655), Auto DevOps
will run on pipelines automatically only if a [`Dockerfile` or matching buildpack](stages.md#auto-build)
exists.

If a [CI/CD configuration file](../../ci/yaml/README.md) is present in the project,
it will continue to be used, whether or not Auto DevOps is enabled.

## Quick start

If you are using GitLab.com, see the [quick start guide](quick_start_guide.md)
for how to use Auto DevOps with GitLab.com and a Kubernetes cluster on Google Kubernetes
Engine (GKE).

If you are using a self-managed instance of GitLab, you will need to configure the
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
  can use a Kubernetes cluster you host or Containers as a Service on any
  public cloud (for example, [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)).
- Auto DevOps has more features including security testing, performance testing,
  and code quality testing.
- Auto DevOps offers an incremental graduation path. If you need advanced customizations,
  you can start modifying the templates without having to start over on a
  completely different platform. Review the [customizing](customize.md) documentation for more information.

## Features

Comprised of a set of stages, Auto DevOps brings these best practices to your
project in a simple and automatic way:

1. [Auto Build](stages.md#auto-build)
1. [Auto Test](stages.md#auto-test)
1. [Auto Code Quality](stages.md#auto-code-quality-starter) **(STARTER)**
1. [Auto SAST (Static Application Security Testing)](stages.md#auto-sast-ultimate) **(ULTIMATE)**
1. [Auto Dependency Scanning](stages.md#auto-dependency-scanning-ultimate) **(ULTIMATE)**
1. [Auto License Compliance](stages.md#auto-license-compliance-ultimate) **(ULTIMATE)**
1. [Auto Container Scanning](stages.md#auto-container-scanning-ultimate) **(ULTIMATE)**
1. [Auto Review Apps](stages.md#auto-review-apps)
1. [Auto DAST (Dynamic Application Security Testing)](stages.md#auto-dast-ultimate) **(ULTIMATE)**
1. [Auto Deploy](stages.md#auto-deploy)
1. [Auto Browser Performance Testing](stages.md#auto-browser-performance-testing-premium) **(PREMIUM)**
1. [Auto Monitoring](stages.md#auto-monitoring)

As Auto DevOps relies on many different components, it's good to have a basic
knowledge of the following:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Helm](https://helm.sh/docs/)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

Auto DevOps provides great defaults for all the stages; you can, however,
[customize](customize.md) almost everything to your needs.

For an overview on the creation of Auto DevOps, read more
[in this blog post](https://about.gitlab.com/blog/2017/06/29/whats-next-for-gitlab-ci/).

NOTE: **Note**
Kubernetes clusters can [be used without](../../user/project/clusters/index.md)
Auto DevOps.

## Requirements

To make full use of Auto DevOps, you will need:

- **Kubernetes** (for Auto Review Apps, Auto Deploy, and Auto Monitoring)

  To enable deployments, you will need:

  1. A [Kubernetes 1.12+ cluster](../../user/project/clusters/index.md) for the project. The easiest
     way is to create a [new cluster using the GitLab UI](../../user/project/clusters/add_remove_clusters.md#create-new-cluster).
     For Kubernetes 1.16+ clusters, there is some additional configuration for [Auto Deploy for Kubernetes 1.16+](stages.md#kubernetes-116).
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

- **cert-manager** (optional, for TLS/HTTPS)

  To enable HTTPS endpoints for your application, you need to install cert-manager,
  a native Kubernetes certificate management controller that helps with issuing certificates.
  Installing cert-manager on your cluster will issue a certificate by
  [Let’s Encrypt](https://letsencrypt.org/) and ensure that certificates are valid and up-to-date.
  If you have configured GitLab's Kubernetes integration, you can deploy it to
  your cluster by installing the
  [GitLab-managed app for cert-manager](../../user/clusters/applications.md#cert-manager).

If you do not have Kubernetes or Prometheus installed, then Auto Review Apps,
Auto Deploy, and Auto Monitoring will be silently skipped.

One all requirements are met, you can go ahead and [enable Auto DevOps](#enablingdisabling-auto-devops).

## Auto DevOps base domain

The Auto DevOps base domain is required if you want to make use of
[Auto Review Apps](stages.md#auto-review-apps), [Auto Deploy](stages.md#auto-deploy), and
[Auto Monitoring](stages.md#auto-monitoring). It can be defined in any of the following
places:

- either under the cluster's settings, whether for [projects](../../user/project/clusters/index.md#base-domain) or [groups](../../user/group/clusters/index.md#base-domain)
- or in instance-wide settings in the **Admin Area > Settings** under the "Continuous Integration and Delivery" section
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
   that will be used by Auto DevOps to [deploy your application](stages.md#auto-deploy)
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

1. Go to **Admin Area > Settings > Continuous Integration and Deployment**.
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

- **Continuous deployment to production**: Enables [Auto Deploy](stages.md#auto-deploy)
  with `master` branch directly deployed to production.
- **Continuous deployment to production using timed incremental rollout**: Sets the
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#timed-incremental-rollout-to-production-premium) variable
  to `timed`, and production deployment will be executed with a 5 minute delay between
  each increment in rollout.
- **Automatic deployment to staging, manual deployment to production**: Sets the
  [`STAGING_ENABLED`](customize.md#deploy-policy-for-staging-and-production-environments) and
  [`INCREMENTAL_ROLLOUT_MODE`](customize.md#incremental-rollout-to-production-premium) variables
  to `1` and `manual`. This means:

  - `master` branch is directly deployed to staging.
  - Manual actions are provided for incremental rollout to production.

## Using multiple Kubernetes clusters **(PREMIUM)**

When using Auto DevOps, you may want to deploy different environments to
different Kubernetes clusters. This is possible due to the 1:1 connection that
[exists between them](../../user/project/clusters/index.md#multiple-kubernetes-clusters-premium).

In the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml) (used behind the scenes by Auto DevOps), there
are currently 3 defined environment names that you need to know:

- `review/` (every environment starting with `review/`)
- `staging`
- `production`

Those environments are tied to jobs that use [Auto Deploy](stages.md#auto-deploy), so
except for the environment scope, they would also need to have a different
domain they would be deployed to. This is why you need to define a separate
`KUBE_INGRESS_BASE_DOMAIN` variable for all the above
[based on the environment](../../ci/variables/README.md#limiting-environment-scopes-of-environment-variables).

The following table is an example of how the three different clusters would
be configured.

| Cluster name | Cluster environment scope | `KUBE_INGRESS_BASE_DOMAIN` variable value | Variable environment scope | Notes |
|--------------|---------------------------|-------------------------------------------|----------------------------|---|
| review       | `review/*`                | `review.example.com`                      | `review/*`                 | The review cluster which will run all [Review Apps](../../ci/review_apps/index.md). `*` is a wildcard, which means it will be used by every environment name starting with `review/`. |
| staging      | `staging`                 | `staging.example.com`                     | `staging`                  | (Optional) The staging cluster which will run the deployments of the staging environments. You need to [enable it first](customize.md#deploy-policy-for-staging-and-production-environments). |
| production   | `production`              | `example.com`                             | `production`               | The production cluster which will run the deployments of the production environment. You can use [incremental rollouts](customize.md#incremental-rollout-to-production-premium). |

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

- Auto Build and Auto Test may fail to detect your language or framework with the
  following error:

  ```plaintext
  Step 5/11 : RUN /bin/herokuish buildpack build
   ---> Running in eb468cd46085
      -----> Unable to select a buildpack
  The command '/bin/sh -c /bin/herokuish buildpack build' returned a non-zero code: 1
  ```

  The following are possible reasons:

  - Your application may be missing the key files the buildpack is looking for. For
    example, for Ruby applications you must have a `Gemfile` to be properly detected,
    even though it is possible to write a Ruby app without a `Gemfile`.
  - There may be no buildpack for your application. Try specifying a
    [custom buildpack](customize.md#custom-buildpacks).
- Auto Test may fail because of a mismatch between testing frameworks. In this
  case, you may need to customize your `.gitlab-ci.yml` with your test commands.
- Auto Deploy will fail if GitLab can not create a Kubernetes namespace and
  service account for your project. For help debugging this issue, see
  [Troubleshooting failed deployment jobs](../../user/project/clusters/index.md#troubleshooting).

## Development guides

[Development guide for Auto DevOps](../../development/auto_devops.md)
