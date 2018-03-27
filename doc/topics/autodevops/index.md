# Auto DevOps

DANGER: Auto DevOps is currently in **Beta** and _not recommended for production use_.

> [Introduced][ce-37115] in GitLab 10.0.

Auto DevOps automatically detects, builds, tests, deploys, and monitors your
applications.

## Overview

With Auto DevOps, the software development process becomes easier to set up
as every project can have a complete workflow from build to deploy and monitoring,
with minimal to zero configuration.

Comprised of a set of stages, Auto DevOps brings these best practices to your
project in an easy and automatic way:

1. [Auto Build](#auto-build)
1. [Auto Test](#auto-test)
1. [Auto Code Quality](#auto-code-quality)
1. [Auto SAST (Static Application Security Testing)](#auto-sast)
1. [Auto Container Scanning](#auto-container-scanning)
1. [Auto Review Apps](#auto-review-apps)
1. [Auto DAST (Dynamic Application Security Testing)](#auto-dast)
1. [Auto Deploy](#auto-deploy)
1. [Auto Browser Performance Testing](#auto-browser-performance-testing)
1. [Auto Monitoring](#auto-monitoring)

As Auto DevOps relies on many different components, it's good to have a basic
knowledge of the following:

- [Kubernetes](https://kubernetes.io/docs/home/)
- [Helm](https://docs.helm.sh/)
- [Docker](https://docs.docker.com)
- [GitLab Runner](https://docs.gitlab.com/runner/)
- [Prometheus](https://prometheus.io/docs/introduction/overview/)

Auto DevOps provides great defaults for all the stages; you can, however,
[customize](#customizing) almost everything to your needs.

For an overview on the creation of Auto DevOps, read the blog post [From 2/3 of the Self-Hosted Git Market, to the Next-Generation CI System, to Auto DevOps](https://about.gitlab.com/2017/06/29/whats-next-for-gitlab-ci/).

## Prerequisites

TIP: **Tip:**
For self-hosted installations, the easiest way to make use of Auto DevOps is to
install GitLab inside a Kubernetes cluster using the [GitLab Omnibus Helm Chart]
which automatically installs and configures everything you need!

To make full use of Auto DevOps, you will need:

1. **GitLab Runner** (needed for all stages) - Your Runner needs to be
   configured to be able to run Docker. Generally this means using the
   [Docker](https://docs.gitlab.com/runner/executors/docker.html) or [Kubernetes
   executor](https://docs.gitlab.com/runner/executors/kubernetes.html), with
   [privileged mode enabled](https://docs.gitlab.com/runner/executors/docker.html#use-docker-in-docker-with-privileged-mode).
   The Runners do not need to be installed in the Kubernetes cluster, but the
   Kubernetes executor is easy to use and is automatically autoscaling.
   Docker-based Runners can be configured to autoscale as well, using [Docker
   Machine](https://docs.gitlab.com/runner/install/autoscaling.html). Runners
   should be registered as [shared Runners](../../ci/runners/README.md#registering-a-shared-runner)
   for the entire GitLab instance, or [specific Runners](../../ci/runners/README.md#registering-a-specific-runner)
   that are assigned to specific projects.
1. **Base domain** (needed for Auto Review Apps and Auto Deploy) - You will need
   a domain configured with wildcard DNS which is gonna be used by all of your
   Auto DevOps applications. [Read the specifics](#auto-devops-base-domain).
1. **Kubernetes** (needed for Auto Review Apps, Auto Deploy, and Auto Monitoring) -
   To enable deployments, you will need Kubernetes 1.5+. You need a [Kubernetes cluster][kubernetes-clusters]
   for the project, or a Kubernetes [default service template](../../user/project/integrations/services_templates.md)
   for the entire GitLab installation.
    1. **A load balancer** - You can use NGINX ingress by deploying it to your
       Kubernetes cluster using the
       [`nginx-ingress`](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
       Helm chart.
    1. **Wildcard TLS termination** - You can deploy the
       [`kube-lego`](https://github.com/kubernetes/charts/tree/master/stable/kube-lego)
       Helm chart to your Kubernetes cluster to automatically issue certificates
       for your domains using Let's Encrypt.
1. **Prometheus** (needed for Auto Monitoring) - To enable Auto Monitoring, you
   will need Prometheus installed somewhere (inside or outside your cluster) and
   configured to scrape your Kubernetes cluster. To get response metrics
   (in addition to system metrics), you need to
   [configure Prometheus to monitor NGINX](../../user/project/integrations/prometheus_library/nginx_ingress.md#configuring-prometheus-to-monitor-for-nginx-ingress-metrics).
   The [Prometheus service](../../user/project/integrations/prometheus.md)
   integration needs to be enabled for the project, or enabled as a
   [default service template](../../user/project/integrations/services_templates.md)
   for the entire GitLab installation.

NOTE: **Note:**
If you do not have Kubernetes or Prometheus installed, then Auto Review Apps,
Auto Deploy, and Auto Monitoring will be silently skipped.

### Auto DevOps base domain

The Auto DevOps base domain is required if you want to make use of [Auto
Review Apps](#auto-review-apps) and [Auto Deploy](#auto-deploy). It is defined
either under the project's CI/CD settings while 
[enabling Auto DevOps](#enabling-auto-devops) or in instance-wide settings in
the CI/CD section.
It can also be set at the project or group level as a variable, `AUTO_DEVOPS_DOMAIN`.

A wildcard DNS A record matching the base domain is required, for example,
given a base domain of `example.com`, you'd need a DNS entry like:

```
*.example.com   3600     A     1.2.3.4
```

where `example.com` is the domain name under which the deployed apps will be served,
and `1.2.3.4` is the IP address of your load balancer; generally NGINX
([see prerequisites](#prerequisites)). How to set up the DNS record is beyond
the scope of this document; you should check with your DNS provider.

Once set up, all requests will hit the load balancer, which in turn will route
them to the Kubernetes pods that run your application(s).

NOTE: **Note:**
If GitLab is installed using the [GitLab Omnibus Helm Chart], there are two
options: provide a static IP, or have one assigned. For more information see the
relevant docs on the [network prerequisites](../../install/kubernetes/gitlab_omnibus.md#networking-prerequisites).

## Quick start

If you are using GitLab.com, see our [quick start guide](quick_start_guide.md)
for using Auto DevOps with GitLab.com and an external Kubernetes cluster on
Google Cloud.

## Enabling Auto DevOps

If you haven't done already, read the [prerequisites](#prerequisites) to make
full use of Auto DevOps. If this is your fist time, we recommend you follow the
[quick start guide](#quick-start).

To enable Auto DevOps to your project:

1. Check that your project doesn't have a `.gitlab-ci.yml`, and remove it otherwise
1. Go to your project's **Settings > CI/CD > General pipelines settings** and
   find the Auto DevOps section
1. Select "Enable Auto DevOps"
1. Optionally, but recommended, add in the [base domain](#auto-devops-base-domain)
   that will be used by Kubernetes to deploy your application
1. Hit **Save changes** for the changes to take effect

Once saved, an Auto DevOps pipeline will be triggered on the default branch.

NOTE: **Note:**
For GitLab versions 10.0 - 10.2, when enabling Auto DevOps, a pipeline needs to be
manually triggered either by pushing a new commit to the repository or by visiting
`https://example.gitlab.com/<username>/<project>/pipelines/new` and creating
a new pipeline for your default branch, generally `master`.

NOTE: **Note:**
If you are a GitLab Administrator, you can enable Auto DevOps instance wide
in **Admin Area > Settings > Continuous Integration and Deployment**. Doing that,
all the projects that haven't explicitly set an option will have Auto DevOps
enabled by default.

## Stages of Auto DevOps

The following sections describe the stages of Auto DevOps. Read them carefully
to understand how each one works.

### Auto Build

Auto Build creates a build of the application in one of two ways:

- If there is a `Dockerfile`, it will use `docker build` to create a Docker image.
- Otherwise, it will use [Herokuish](https://github.com/gliderlabs/herokuish)
  and [Heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks)
  to automatically detect and build the application into a Docker image.

Either way, the resulting Docker image is automatically pushed to the
[Container Registry][container-registry] and tagged with the commit SHA.

CAUTION: **Important:**
If you are also using Auto Review Apps and Auto Deploy and choose to provide
your own `Dockerfile`, make sure you expose your application to port
`5000` as this is the port assumed by the default Helm chart.

### Auto Test

Auto Test automatically runs the appropriate tests for your application using
[Herokuish](https://github.com/gliderlabs/herokuish) and [Heroku
buildpacks](https://devcenter.heroku.com/articles/buildpacks) by analyzing
your project to detect the language and framework. Several languages and
frameworks are detected automatically, but if your language is not detected,
you may succeed with a [custom buildpack](#custom-buildpacks). Check the
[currently supported languages](#currently-supported-languages).

NOTE: **Note:**
Auto Test uses tests you already have in your application. If there are no
tests, it's up to you to add them.

### Auto Code Quality

Auto Code Quality uses the open source
[`codeclimate` image](https://hub.docker.com/r/codeclimate/codeclimate/) to run
static analysis and other code checks on the current code. The report is
created, and is uploaded as an artifact which you can later download and check
out.

In GitLab Starter, differences between the source and
target branches are also
[shown in the merge request widget](https://docs.gitlab.com/ee/user/project/merge_requests/code_quality_diff.html).

### Auto SAST

> Introduced in [GitLab Ultimate][ee] 10.3.

Static Application Security Testing (SAST) uses the
[gl-sast Docker image](https://gitlab.com/gitlab-org/gl-sast) to run static
analysis on the current code and checks for potential security issues. Once the
report is created, it's uploaded as an artifact which you can later download and
check out.

In GitLab Ultimate, any security warnings are also
[shown in the merge request widget](https://docs.gitlab.com/ee/user/project/merge_requests/sast.html).

### Auto Container Scanning

> Introduced in GitLab 10.4.

Vulnerability Static Analysis for containers uses
[Clair](https://github.com/coreos/clair) to run static analysis on a
Docker image and checks for potential security issues. Once the report is
created, it's uploaded as an artifact which you can later download and
check out.

In GitLab Ultimate, any security warnings are also
[shown in the merge request widget](https://docs.gitlab.com/ee/user/project/merge_requests/container_scanning.html).

### Auto Review Apps

NOTE: **Note:**
This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [prerequisites](#prerequisites) are not met, the job will
silently be skipped.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly.)
This can cause confusion with Helm not detecting the change, and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

[Review Apps][review-app] are temporary application environments based on the
branch's code so developers, designers, QA, product managers, and other
reviewers can actually see and interact with code changes as part of the review
process. Auto Review Apps create a Review App for each branch.

The Review App will have a unique URL based on the project name, the branch
name, and a unique number, combined with the Auto DevOps base domain. For
example, `user-project-branch-1234.example.com`. A link to the Review App shows
up in the merge request widget for easy discovery. When the branch is deleted,
for example after the merge request is merged, the Review App will automatically
be deleted.

### Auto DAST

> Introduced in [GitLab Ultimate][ee] 10.4.

Dynamic Application Security Testing (DAST) uses the
popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on the current code and checks for potential security
issues. Once the report is created, it's uploaded as an artifact which you can
later download and check out.

In GitLab Ultimate, any security warnings are also
[shown in the merge request widget](https://docs.gitlab.com/ee/user/project/merge_requests/dast.html).

### Auto Browser Performance Testing

> Introduced in [GitLab Premium][ee] 10.4.

Auto Browser Performance Testing utilizes the [Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/) to measure the performance of a web page. A JSON report is created and uploaded as an artifact, which includes the overall performance score for each page. By default, the root page of Review and Production environments will be tested. If you would like to add additional URL's to test, simply add the paths to a file named `.gitlab-urls.txt` in the root directory, one per line. For example:

```
/
/features
/direction
```

In GitLab Premium, performance differences between the source and target branches are [shown in the merge request widget](https://docs.gitlab.com/ee/user/project/merge_requests/browser_performance_testing.html).

### Auto Deploy

NOTE: **Note:**
This is an optional step, since many projects do not have a Kubernetes cluster
available. If the [prerequisites](#prerequisites) are not met, the job will
silently be skipped.

CAUTION: **Caution:**
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly.)
This can cause confusion with Helm not detecting the change, and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old config.

After a branch or merge request is merged into the project's default branch (usually
`master`), Auto Deploy deploys the application to a `production` environment in
the Kubernetes cluster, with a namespace based on the project name and unique
project ID, for example `project-4321`.

Auto Deploy doesn't include deployments to staging or canary by default, but the
[Auto DevOps template] contains job definitions for these tasks if you want to
enable them.

You can make use of [environment variables](#helm-chart-variables) to automatically
scale your pod replicas.

It's important to note that when a project is deployed to a Kubernetes cluster,
it relies on a Docker image that has been pushed to the
[GitLab Container Registry](../../user/project/container_registry.md). Kubernetes
fetches this image and uses it to run the application. If the project is public,
the image can be accessed by Kubernetes without any authentication, allowing us
to have deployments more usable. If the project is private/internal, the
Registry requires credentials to pull the image. Currently, this is addressed
by providing `CI_JOB_TOKEN` as the password that can be used, but this token will
no longer be valid as soon as the deployment job finishes. This means that
Kubernetes can run the application, but in case it should be restarted or
executed somewhere else, it cannot be accessed again.

### Auto Monitoring

NOTE: **Note:**
Check the [prerequisites](#prerequisites) for Auto Monitoring to make this stage
work.

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

If GitLab has been deployed using the [GitLab Omnibus Helm Chart], no
configuration is required.

If you have installed GitLab using a different method, you need to:

1. [Deploy Prometheus](../../user/project/integrations/prometheus.md#configuring-your-own-prometheus-server-within-kubernetes) into your Kubernetes cluster
1. If you would like response metrics, ensure you are running at least version
   0.9.0 of NGINX Ingress and
   [enable Prometheus metrics](https://github.com/kubernetes/ingress/blob/master/examples/customization/custom-vts-metrics/nginx/nginx-vts-metrics-conf.yaml).
1. Finally, [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
   the NGINX Ingress deployment to be scraped by Prometheus using
   `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

To view the metrics, open the
[Monitoring dashboard for a deployed environment](../../ci/environments.md#monitoring-environments).

![Auto Metrics](img/auto_monitoring.png)

## Customizing

While Auto DevOps provides great defaults to get you started, you can customize
almost everything to fit your needs; from custom [buildpacks](#custom-buildpacks),
to [`Dockerfile`s](#custom-dockerfile), [Helm charts](#custom-helm-chart), or
even copying the complete [CI/CD configuration](#customizing-gitlab-ci-yml)
into your project to enable staging and canary deployments, and more.

### Custom buildpacks

If the automatic buildpack detection fails for your project, or if you want to
use a custom buildpack, you can override the buildpack using a project variable
or a `.buildpack` file in your project:

- **Project variable** - Create a project variable `BUILDPACK_URL` with the URL
  of the buildpack to use.
- **`.buildpack` file** - Add a file in your project's repo called  `.buildpack`
  and add the URL of the buildpack to use on a line in the file. If you want to
  use multiple buildpacks, you can enter them in, one on each line.

CAUTION: **Caution:**
Using multiple buildpacks isn't yet supported by Auto DevOps.

### Custom `Dockerfile`

If your project has a `Dockerfile` in the root of the project repo, Auto DevOps
will build a Docker image based on the Dockerfile rather than using buildpacks.
This can be much faster and result in smaller images, especially if your
Dockerfile is based on [Alpine](https://hub.docker.com/_/alpine/).

### Custom Helm Chart

Auto DevOps uses [Helm](https://helm.sh/) to deploy your application to Kubernetes.
You can override the Helm chart used by bundling up a chart into your project
repo or by specifying a project variable:

- **Bundled chart** - If your project has a `./chart` directory with a `Chart.yaml`
  file in it, Auto DevOps will detect the chart and use it instead of the [default
  one](https://gitlab.com/charts/charts.gitlab.io/tree/master/charts/auto-deploy-app).
  This can be a great way to control exactly how your application is deployed.
- **Project variable** - Create a [project variable](../../ci/variables/README.md#secret-variables)
  `AUTO_DEVOPS_CHART` with the URL of a custom chart to use.

### Customizing `.gitlab-ci.yml`

If you want to modify the CI/CD pipeline used by Auto DevOps, you can copy the
[Auto DevOps template] into your project's repo and edit as you see fit.

Assuming that your project is new or it doesn't have a `.gitlab-ci.yml` file
present:

1. From your project home page, either click on the "Set up CI/CD" button, or click
   on the plus button and (`+`), then "New file"
1. Pick `.gitlab-ci.yml` as the template type
1. Select "Auto-DevOps" from the template dropdown
1. Edit the template or add any jobs needed
1. Give an appropriate commit message and hit "Commit changes"

TIP: **Tip:** The Auto DevOps template includes useful comments to help you
customize it. For example, if you want deployments to go to a staging environment
instead of directly to a production one, you can enable the `staging` job by
renaming `.staging` to `staging`. Then make sure to uncomment the `when` key of
the `production` job to turn it into a manual action instead of deploying
automatically.

### PostgreSQL database support

In order to support applications that require a database,
[PostgreSQL][postgresql] is provisioned by default. The credentials to access
the database are preconfigured, but can be customized by setting the associated
[variables](#environment-variables). These credentials can be used for defining a
`DATABASE_URL` of the format:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### Environment variables

The following variables can be used for setting up the Auto DevOps domain,
providing a custom Helm chart, or scaling your application. PostgreSQL can be
also be customized, and you can easily use a [custom buildpack](#custom-buildpacks).

| **Variable** | **Description** |
| ------------ | --------------- |
| `AUTO_DEVOPS_DOMAIN`        | The [Auto DevOps domain](#auto-devops-domain); by default set automatically by the [Auto DevOps setting](#enabling-auto-devops). |
| `AUTO_DEVOPS_CHART`         | The Helm Chart used to deploy your apps; defaults to the one [provided by GitLab](https://gitlab.com/charts/charts.gitlab.io/tree/master/charts/auto-deploy-app). |
| `PRODUCTION_REPLICAS`       | The number of replicas to deploy in the production environment; defaults to 1. |
| `STAGING_REPLICAS`          | The number of replicas to deploy in the staging environment; defaults to 1. This is only applicable if you've [customized the auto devops template to enable staging](#customizing-gitlab-ci-yml) |
| `CANARY_PRODUCTION_REPLICAS`| The number of canary replicas to deploy for [Canary Deployments](https://docs.gitlab.com/ee/user/project/canary_deployments.html) in the production environment. |
| `POSTGRES_ENABLED`          | Whether PostgreSQL is enabled; defaults to `"true"`. Set to `false` to disable the automatic deployment of PostgreSQL. |
| `POSTGRES_USER`             | The PostgreSQL user; defaults to `user`. Set it to use a custom username. |
| `POSTGRES_PASSWORD`         | The PostgreSQL password; defaults to `testing-password`. Set it to use a custom password. |
| `POSTGRES_DB`               | The PostgreSQL database name; defaults to the value of [`$CI_ENVIRONMENT_SLUG`](../../ci/variables/README.md#predefined-variables-environment-variables). Set it to use a custom database name. |
| `BUILDPACK_URL`             | The buildpack's full URL. It can point to either Git repositories or a tarball URL. For Git repositories, it is possible to point to a specific `ref`, for example `https://github.com/heroku/heroku-buildpack-ruby.git#v142`|

TIP: **Tip:**
Set up the replica variables using a
[project variable](../../ci/variables/README.md#secret-variables)
and scale your application by just redeploying it!

CAUTION: **Caution:**
You should *not* scale your application using Kubernetes directly. This can
cause confusion with Helm not detecting the change, and subsequent deploys with
Auto DevOps can undo your changes.

## Currently supported languages

NOTE: **Note:**
Not all buildpacks support Auto Test yet, as it's a relatively new
enhancement. All of Heroku's [officially supported
languages](https://devcenter.heroku.com/articles/heroku-ci#currently-supported-languages)
support it, and some third-party buildpacks as well e.g., Go, Node, Java, PHP,
Python, Ruby, Gradle, Scala, and Elixir all support Auto Test, but notably the
multi-buildpack does not.

As of GitLab 10.0, the supported buildpacks are:

```
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

### Private project support

CAUTION: **Caution:** Private project support in Auto DevOps is experimental.

When a project has been marked as private, GitLab's [Container
Registry][container-registry] requires authentication when downloading
containers. Auto DevOps will automatically provide the required authentication
information to Kubernetes, allowing temporary access to the registry.
Authentication credentials will be valid while the pipeline is running, allowing
for a successful initial deployment.

After the pipeline completes, Kubernetes will no longer be able to access the
Container Registry. **Restarting a pod, scaling a service, or other actions which
require on-going access to the registry may fail**. On-going secure access is
planned for a subsequent release.

## Troubleshooting

- Auto Build and Auto Test may fail in detecting your language/framework. There
  may be no buildpack for your application, or your application may be missing the
  key files the buildpack is looking for. For example, for ruby apps, you must
  have a `Gemfile` to be properly detected, even though it is possible to write a
  Ruby app without a `Gemfile`. Try specifying a [custom
  buildpack](#custom-buildpacks).
- Auto Test may fail because of a mismatch between testing frameworks. In this
  case, you may need to customize your `.gitlab-ci.yml` with your test commands.

### Disable the banner instance wide

If an administrator would like to disable the banners on an instance level, this
feature can be disabled either through the console:

```sh
sudo gitlab-rails console
```

Then run:

```ruby
Feature.get(:auto_devops_banner_disabled).enable
```

Or through the HTTP API with an admin access token:

```sh
curl --data "value=true" --header "PRIVATE-TOKEN: personal_access_token" https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled
```

[ce-37115]: https://gitlab.com/gitlab-org/gitlab-ce/issues/37115
[kubernetes-clusters]: ../../user/project/clusters/index.md
[docker-in-docker]: ../../docker/using_docker_build.md#use-docker-in-docker-executor
[review-app]: ../../ci/review_apps/index.md
[container-registry]: ../../user/project/container_registry.md
[postgresql]: https://www.postgresql.org/
[Auto DevOps template]: https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml
[GitLab Omnibus Helm Chart]: ../../install/kubernetes/gitlab_omnibus.md
[ee]: https://about.gitlab.com/products/
