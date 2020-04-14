# Stages of Auto DevOps

The following sections describe the stages of Auto DevOps. Read them carefully
to understand how each one works.

## Auto Build

Auto Build creates a build of the application using an existing `Dockerfile` or
Heroku buildpacks.

Either way, the resulting Docker image is automatically pushed to the
[Container Registry](../../user/packages/container_registry/index.md) and tagged with the commit SHA or tag.

### Auto Build using a Dockerfile

If a project's repository contains a `Dockerfile` at its root, Auto Build will use
`docker build` to create a Docker image.

If you are also using Auto Review Apps and Auto Deploy and choose to provide
your own `Dockerfile`, make sure you expose your application to port
`5000` as this is the port assumed by the
[default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app). Alternatively you can override the default values by [customizing the Auto Deploy Helm chart](customize.md#custom-helm-chart)

### Auto Build using Heroku buildpacks

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

### Auto Build using Cloud Native Buildpacks (beta)

> Introduced in [GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28165).

Auto Build supports building your application using [Cloud Native Buildpacks](https://buildpacks.io)
through the [`pack` command](https://github.com/buildpacks/pack). To use Cloud Native Buildpacks,
set the CI variable `AUTO_DEVOPS_BUILD_IMAGE_CNB_ENABLED` to a non-empty value.

Cloud Native Buildpacks (CNBs) are an evolution of Heroku buildpacks, and
will eventually supersede Herokuish-based builds within Auto DevOps. For more
information, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/212692).

Builds using Cloud Native Buildpacks support the same options as builds using
Heroku buildpacks, with the following caveats:

- The buildpack must be a Cloud Native Buildpack. A Heroku buildpack can be
  converted to a Cloud Native Buildpack using Heroku's
  [`cnb-shim`](https://github.com/heroku/cnb-shim).
- `BUILDPACK_URL` must be in a form
  [supported by `pack`](https://buildpacks.io/docs/app-developer-guide/specific-buildpacks/).
- The `/bin/herokuish` command is not present in the resulting image, and prefixing
  commands with `/bin/herokuish procfile exec` is no longer required (nor possible).

NOTE: **Note**: Auto Test still uses Herokuish, as test suite detection is not
yet part of the Cloud Native Buildpack specification. For more information, see
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/212689).

## Auto Test

Auto Test automatically runs the appropriate tests for your application using
[Herokuish](https://github.com/gliderlabs/herokuish) and [Heroku
buildpacks](https://devcenter.heroku.com/articles/buildpacks) by analyzing
your project to detect the language and framework. Several languages and
frameworks are detected automatically, but if your language is not detected,
you may succeed with a [custom buildpack](customize.md#custom-buildpacks). Check the
[currently supported languages](index.md#currently-supported-languages).

Auto Test uses tests you already have in your application. If there are no
tests, it's up to you to add them.

## Auto Code Quality **(STARTER)**

Auto Code Quality uses the
[Code Quality image](https://gitlab.com/gitlab-org/ci-cd/codequality) to run
static analysis and other code checks on the current code. The report is
created, and is uploaded as an artifact which you can later download and check
out.

Any differences between the source and target branches are also
[shown in the merge request widget](../../user/project/merge_requests/code_quality.md).

## Auto SAST **(ULTIMATE)**

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.

Static Application Security Testing (SAST) uses the
[SAST Docker image](https://gitlab.com/gitlab-org/security-products/sast) to run static
analysis on the current code and checks for potential security issues. The
Auto SAST stage will be skipped on licenses other than Ultimate and requires GitLab Runner 11.5 or above.

Once the report is created, it's uploaded as an artifact which you can later download and
check out.

Any security warnings are also shown in the merge request widget. Read more how
[SAST works](../../user/application_security/sast/index.md).

## Auto Dependency Scanning **(ULTIMATE)**

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.7.

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

## Auto License Compliance **(ULTIMATE)**

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.0.

License Compliance uses the
[License Compliance Docker image](https://gitlab.com/gitlab-org/security-products/license-management)
to search the project dependencies for their license. The Auto License Compliance stage
will be skipped on licenses other than Ultimate.

Once the
report is created, it's uploaded as an artifact which you can later download and
check out.

Any licenses are also shown in the merge request widget. Read more how
[License Compliance works](../../user/compliance/license_compliance/index.md).

## Auto Container Scanning **(ULTIMATE)**

> Introduced in GitLab 10.4.

Vulnerability Static Analysis for containers uses
[Clair](https://github.com/quay/clair) to run static analysis on a
Docker image and checks for potential security issues. The Auto Container Scanning stage
will be skipped on licenses other than Ultimate.

Once the report is
created, it's uploaded as an artifact which you can later download and
check out.

Any security warnings are also shown in the merge request widget. Read more how
[Container Scanning works](../../user/application_security/container_scanning/index.md).

## Auto Review Apps

This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [requirements](index.md#requirements) are not met, the job will
silently be skipped.

[Review Apps](../../ci/review_apps/index.md) are temporary application environments based on the
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
Helm, which can be [customized](customize.md#custom-helm-chart). The app will be deployed into the [Kubernetes
namespace](../../user/project/clusters/index.md#deployment-variables)
for the environment.

Since GitLab 11.4, a [local
Tiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

## Auto DAST **(ULTIMATE)**

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.4.

Dynamic Application Security Testing (DAST) uses the
popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on the current code and checks for potential security
issues. The Auto DAST stage will be skipped on licenses other than Ultimate.

Once the DAST scan is complete, any security warnings are shown
on the [Security Dashboard](../../user/application_security/security_dashboard/index.md)
and the Merge Request Widget. Read how
[DAST works](../../user/application_security/dast/index.md).

On your default branch, DAST scans an app deployed specifically for that purpose.
The app is deleted after DAST has run.

On feature branches, DAST scans the [review app](#auto-review-apps).

### Overriding the DAST target

To use a custom target instead of the auto-deployed review apps,
set a `DAST_WEBSITE` environment variable to the URL for DAST to scan.

NOTE: **Note:**
If [DAST Full Scan](../../user/application_security/dast/index.md#full-scan) is enabled, it is strongly advised **not**
to set `DAST_WEBSITE` to any staging or production environment. DAST Full Scan
actively attacks the target, which can take down the application and lead to
data loss or corruption.

### Disabling Auto DAST

DAST can be disabled:

- On all branches by setting the `DAST_DISABLED` environment variable to `"true"`.
- Only on the default branch by setting the `DAST_DISABLED_FOR_DEFAULT_BRANCH` environment variable to `"true"`.

## Auto Browser Performance Testing **(PREMIUM)**

> Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 10.4.

Auto Browser Performance Testing utilizes the [Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/) to measure the performance of a web page. A JSON report is created and uploaded as an artifact, which includes the overall performance score for each page. By default, the root page of Review and Production environments will be tested. If you would like to add additional URL's to test, simply add the paths to a file named `.gitlab-urls.txt` in the root directory, one per line. For example:

```text
/
/features
/direction
```

Any performance differences between the source and target branches are also
[shown in the merge request widget](../../user/project/merge_requests/browser_performance_testing.md).

## Auto Deploy

This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [requirements](index.md#requirements) are not met, the job will
silently be skipped.

After a branch or merge request is merged into the project's default branch (usually
`master`), Auto Deploy deploys the application to a `production` environment in
the Kubernetes cluster, with a namespace based on the project name and unique
project ID, for example `project-4321`.

Auto Deploy doesn't include deployments to staging or canary by default, but the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml) contains job definitions for these tasks if you want to
enable them.

You can make use of [environment variables](customize.md#environment-variables) to automatically
scale your pod replicas and to apply custom arguments to the Auto DevOps `helm upgrade` commands. This is an easy way to [customize the Auto Deploy Helm chart](customize.md#custom-helm-chart).

Apps are deployed using the
[auto-deploy-app](https://gitlab.com/gitlab-org/charts/auto-deploy-app) chart with
Helm. The app will be deployed into the [Kubernetes
namespace](../../user/project/clusters/index.md#deployment-variables)
for the environment.

Since GitLab 11.4, a [local
Tiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19507) in GitLab 11.0.

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

### Kubernetes 1.16+

> - [Introduced](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/51) in GitLab 12.8.
> - Support for deploying a PostgreSQL version that supports Kubernetes 1.16+ was [introduced](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/merge_requests/49) in GitLab 12.9.

CAUTION: **Deprecation**
The default value of `extensions/v1beta1` for the `deploymentApiVersion` setting is
deprecated, and is scheduled to be changed to a new default of `apps/v1` in
[GitLab 13.0](https://gitlab.com/gitlab-org/charts/auto-deploy-app/issues/47).

In Kubernetes 1.16 onwards, a number of [APIs were removed](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/),
including support for `Deployment` in the `extensions/v1beta1` version.

To use Auto Deploy on a Kubernetes 1.16+ cluster, you must:

1. Set the following in the [`.gitlab/auto-deploy-values.yaml` file](customize.md#customize-values-for-helm-chart):

   ```yml
   deploymentApiVersion: apps/v1
   ```

1. Set the:

   - `AUTO_DEVOPS_POSTGRES_CHANNEL` variable to `2`.
   - `POSTGRES_VERSION` variable to `9.6.16` or higher.

   This will opt-in to using a version of the PostgreSQL chart that supports Kubernetes
   1.16 and higher.

DANGER: **Danger:** Opting into `AUTO_DEVOPS_POSTGRES_CHANNEL` version
`2` will delete the version `1` PostgreSQL database. Please follow the
guide on [upgrading PostgreSQL](upgrading_postgresql.md) to backup and
restore your database before opting into version `2`.

### Migrations

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/21955) in GitLab 11.4

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

### Workers

Some web applications need to run extra deployments for "worker processes". For
example, it is common in a Rails application to have a separate worker process
to run background tasks like sending emails.

The [default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app)
used in Auto Deploy [has support for running worker
processes](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/9).

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
worker for your Rails application. You can enable workers by setting the
following in the [`.gitlab/auto-deploy-values.yaml` file](customize.md#customize-values-for-helm-chart):

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

### Network Policy

> [Introduced](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/30) in GitLab 12.7.

By default, all Kubernetes pods are
[non-isolated](https://kubernetes.io/docs/concepts/services-networking/network-policies/#isolated-and-non-isolated-pods),
meaning that they will accept traffic to and from any source. You can use
[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
to restrict connections to and from selected pods, namespaces, and the Internet.

NOTE: **Note:**
You must use a Kubernetes network plugin that implements support for
`NetworkPolicy`. The default network plugin for Kubernetes (`kubenet`)
[does not implement](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#kubenet)
support for it. The [Cilium](https://cilium.io/) network plugin can be
installed as a [cluster application](../../user/clusters/applications.md#install-cilium-using-gitlab-cicd)
to enable support for network policies.

You can enable deployment of a network policy by setting the following
in the `.gitlab/auto-deploy-values.yaml` file:

```yaml
networkPolicy:
  enabled: true
```

The default policy deployed by the auto deploy pipeline will allow
traffic within a local namespace and from the `gitlab-managed-apps`
namespace. All other inbound connection will be blocked. Outbound
traffic (for example, to the Internet) is not affected by the default policy.

You can also provide a custom [policy specification](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/#networkpolicyspec-v1-networking-k8s-io)
via the `.gitlab/auto-deploy-values.yaml` file, for example:

```yaml
networkPolicy:
  enabled: true
  spec:
    podSelector:
      matchLabels:
        app.gitlab.com/env: staging
    ingress:
    - from:
      - podSelector:
          matchLabels: {}
      - namespaceSelector:
          matchLabels:
            app.gitlab.com/managed_by: gitlab
```

For more information on how to install Network Policies, see
[Install Cilium using GitLab CI/CD](../../user/clusters/applications.md#install-cilium-using-gitlab-cicd).

### Web Application Firewall (ModSecurity) customization

> [Introduced](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/44) in GitLab 12.8.

Customization on an [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) or on a deployment base is available for clusters with [ModSecurity installed](../../user/clusters/applications.md#web-application-firewall-modsecurity).

To enable ModSecurity with Auto Deploy, you need to create a `.gitlab/auto-deploy-values.yaml` file in your project with the following attributes.

|Attribute | Description | Default |
-----------|-------------|---------|
|`enabled` | Enables custom configuration for modsecurity, defaulting to the [Core Rule Set](https://coreruleset.org/) | `false` |
|`secRuleEngine` | Configures the [rules engine](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#secruleengine) | `DetectionOnly` |
|`secRules` | Creates one or more additional [rule](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRule) | `nil` |

In the following `auto-deploy-values.yaml` example, some custom settings
are enabled for ModSecurity. Those include setting its engine to
process rules instead of only logging them, while adding two specific
rules which are header-based:

```yaml
ingress:
  modSecurity:
    enabled: true
    secRuleEngine: "On"
    secRules:
      - variable: "REQUEST_HEADERS:User-Agent"
        operator: "printer"
        action: "log,deny,id:'2010',status:403,msg:'printer is an invalid agent'"
      - variable: "REQUEST_HEADERS:Content-Type"
        operator: "text/plain"
        action: "log,deny,id:'2011',status:403,msg:'Text is not supported as content type'"
```

### Running commands in the container

Applications built with [Auto Build](#auto-build) using Herokuish, the default
unless you have [a custom Dockerfile](#auto-build-using-a-dockerfile), may require
commands to be wrapped as follows:

```shell
/bin/herokuish procfile exec $COMMAND
```

This might be necessary, for example, when:

- Attaching using `kubectl exec`.
- Using GitLab's [Web Terminal](../../ci/environments.md#web-terminals).

For example, to start a Rails console from the application root directory, run:

```shell
/bin/herokuish procfile exec bin/rails c
```

## Auto Monitoring

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

GitLab provides some initial alerts for you after you install Prometheus:

- Ingress status code `500` > 0.1%
- NGINX status code `500` > 0.1%

To make use of Auto Monitoring:

1. [Install and configure the requirements](index.md#requirements).
1. [Enable Auto DevOps](index.md#enablingdisabling-auto-devops) if you haven't done already.
1. Finally, go to your project's **CI/CD > Pipelines** and run a pipeline.
1. Once the pipeline finishes successfully, open the
   [monitoring dashboard for a deployed environment](../../ci/environments.md#monitoring-environments)
   to view the metrics of your deployed application. To view the metrics of the
   whole Kubernetes cluster, navigate to **Operations > Metrics**.

![Auto Metrics](img/auto_monitoring.png)
