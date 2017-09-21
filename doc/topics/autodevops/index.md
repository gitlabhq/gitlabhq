# Auto DevOps

> [Introduced][ce-37115] in GitLab 10.0. Auto DevOps is currently in Beta and
**not recommended for production use**. Access to the Container Registry is only
available while the pipeline is running. Restarting a pod, scaling a service, or
other actions which require on-going access **will fail** even for public
projects. On-going secure access is planned for a subsequent release.

Auto DevOps brings best practices to your project in an easy and default way. A
typical web project starts with Continuous Integration (CI), then adds automated
deployment to production, and maybe some time in the future adds some kind of
monitoring. With Auto DevOps, every project has a complete workflow, with
no configuration, including:

- [Auto Build](#auto-build)
- [Auto Test](#auto-test)
- [Auto Code Quality](#auto-code-quality)
- [Auto Review Apps](#auto-review-apps)
- [Auto Deploy](#auto-deploy)
- [Auto Monitoring](#-auto-monitoring)

## Overview

You will need [Kubernetes](https://kubernetes.io/) and
[Prometheus](https://prometheus.io/) to make full use of Auto DevOps, but
even projects using only [GitLab Runners](https://docs.gitlab.com/runner/) will
be able to make use of Auto Build, Auto Test, and Auto Code Quality.

Auto DevOps makes use of an open source tool called
[Herokuish](https://github.com/gliderlabs/herokuish) which uses [Heroku
buildpacks](https://devcenter.heroku.com/articles/buildpacks) to automatically
detect, build, and test applications. Auto DevOps supports all of the languages
and frameworks that are [supported by
Herokuish](https://github.com/gliderlabs/herokuish#buildpacks) such as Ruby,
Rails, Node, PHP, Python, and Java, and [custom buildpacks can be
specified](#using-custom-buildpacks). *GitLab is in no way affiliated with Heroku
or Glider Labs.*

Projects can [customize](#customizing) the process by specifying [custom
buildpacks](#custom-buildpack), [custom `Dockerfile`s](#custom-dockerfile),
[custom Helm charts](#custom-helm-chart), or even copying the complete CI/CD
configuration into your project to enable staging and canary deployments, and
more.

## Quick start

If you are using GitLab.com, see our [quick start guide](quick_start_guide.md)
for using Auto DevOps with GitLab.com and an external Kubernetes cluster on
Google Cloud.

For self-hosted installations, the easiest way to make use of Auto DevOps is to
install GitLab inside a Kubernetes cluster using the [GitLab-Omnibus Helm
Chart](../../install/kubernetes/gitlab_omnibus.md) which automatically installs
and configures everything you need.

## Prerequisites

You will need one or more GitLab Runners, a Kubernetes cluster, and Prometheus
installed in the cluster to make full use of Auto DevOps. If you do not have
Kubernetes or Prometheus installed then Auto Review Apps, Auto Deploy, and Auto
Monitoring will be silently skipped.

If you are using GitLab outside of Kubernetes, for example with GitLab.com, then
you should take these prerequisites into account:

1. **Base domain** - You will need a base domain configured with wildcard DNS to
   be used by all of your Auto DevOps applications.

1. **GitLab Runner** - Your Runner needs to be configured to be able to run Docker.
   Generally this means using the
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

1. **Kubernetes** - To enable deploys, you will need Kubernetes 1.5+, with NGINX
   ingress and wildcard SSL termination, for example using the
   [`nginx-ingress`](https://github.com/kubernetes/charts/tree/master/stable/nginx-ingress)
   and [`kube-lego`](https://github.com/kubernetes/charts/tree/master/stable/kube-lego)
   Helm charts respectively. The [Kubernetes service][kubernetes-service]
   integration will need to be enabled for the project, or enabled as a
   [default service template](../../user/project/integrations/services_templates.md)
   for the entire GitLab installation.

1. **Prometheus** - To enable Auto Monitoring, you will need Prometheus installed
   somewhere (inside or outside your cluster) and configured to scrape your
   Kubernetes cluster. To get response metrics (in addition to system metrics),
   you need to [configure Prometheus to monitor NGINX](../../user/project/integrations/prometheus_library/nginx_ingress.md#configuring-prometheus-to-monitor-for-nginx-ingress-metrics).
   The [Prometheus service](../../user/project/integrations/prometheus.md)
   integration needs to be enabled for the project, or enabled as a
   [default service template](../../user/project/integrations/services_templates.md)
   for the entire GitLab installation.

## Enabling Auto DevOps

In your GitLab.com project, go to **Settings > CI/CD** and find the Auto DevOps
section. Select "Enable Auto DevOps", add in your base domain, and save.

![auto devops settings](img/auto_devops_settings.png)

## Stages of Auto DevOps

The following sections describe the stages of Auto DevOps.

### Auto Build

Auto Build creates a build of the application in one of two ways:

- If there is a `Dockerfile`, it will use `docker build` to create a Docker image.
- Otherwise, it will use [Herokuish](https://github.com/gliderlabs/herokuish)
  and [Heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks)
  to automatically detect and build the application into a Docker image.

Either way, the resulting Docker image is automatically pushed to the
[Container Registry][container-registry], tagged with the commit SHA.

### Auto Test

Auto Test automatically tests your application using
[Herokuish](https://github.com/gliderlabs/herokuish) and [Heroku
buildpacks](https://devcenter.heroku.com/articles/buildpacks). Auto Test will
analyze your project to detect the language and framework, and run appropriate
tests. Several languages and frameworks are detected automatically, but if your
language is not detected, you may succeed with a [custom
buildpack](#custom-buildpack).

Auto Test uses tests you already have in your application. If there are no
tests, it's up to you to add them.

### Auto Code Quality

Auto Code Quality uses the open source
[`codeclimate` image](https://hub.docker.com/r/codeclimate/codeclimate/) to run
static analysis and other code checks on the current code, creating a report
that is uploaded as an artifact. In GitLab EE, differences between the source
and target branches are shown in the merge request widget. *GitLab is in no way
affiliated with Code Climate.*

### Auto Review Apps

Auto Review Apps create a [Review App][review-app] for each branch. Review Apps
are temporary application environments based on the branch's code so developers,
designers, QA, product managers, and other reviewers can actually see and
interact with code changes as part of the review process.

The review app will have a unique URL based on the project name, the branch
name, and a unique number, combined with the Auto DevOps base domain. For
example, `user-project-branch-1234.example.com`. A link to the Review App shows
up in the merge request widget for easy discovery. When the branch is deleted,
for example after the merge request is merged, the Review App will automatically
be deleted.

This is an optional step, since many projects do not have a Kubernetes cluster
available. If the Kubernetes service is not configured, or if the variable
`AUTO_DEVOPS_DOMAIN` is not available (usually set automatically by the Auto
DevOps setting), the job will silently be skipped.

### Auto Deploy

After a branch or merge request is merged into `master`, Auto Deploy deploys the
application to a `production` environment in the Kubernetes cluster, with a
namespace based on the project name and unique project ID. e.g. `project-4321`.
This is an optional step, since many projects do not have a Kubernetes cluster
available. If the Kubernetes service is not configured, or if the variable
`AUTO_DEVOPS_DOMAIN` is not available (usually set automatically by the Auto
DevOps setting), the job will silently be skipped.

Auto Deploy doesn't include deployments to staging or canary by default, but the
Auto DevOps template contains job definitions for these tasks if you want to
enable them.

### Auto Monitoring

Once your application is deployed, Auto Monitoring makes it possible to monitor
your application's server and response metrics right out of the box. Auto
Monitoring uses [Prometheus](../../user/project/integrations/prometheus.md) to
get system metrics such as CPU and memory usage directly from
[Kubernetes](../../user/project/integrations/prometheus_library/kubernetes.md),
and response metrics such as HTTP error rates, latency, and throughput from the
[NGINX
server](../../user/project/integrations/prometheus_library/nginx_ingress.md).

* Response Metrics: latency, throughput, error rate
* System Metrics: CPU utilization, memory utilization

To view the metrics, open the [Monitoring dashboard for a deployed environment](../../ci/environments.md#monitoring-environments).

![Auto Metrics](img/auto_monitoring.png)

### Configuring Auto Monitoring

If GitLab has been deployed using the
[omnibus-gitlab](../../install/kubernetes/gitlab_omnibus.md) Helm chart, no
configuration is required.

If you have installed GitLab using a different method:

1. [Deploy Prometheus](../../user/project/integrations/prometheus.md#configuring-your-own-prometheus-server-within-kubernetes) into your Kubernetes cluster
1. If you would like response metrics, ensure you are running at least version 0.9.0 of NGINX Ingress and [enable Prometheus metrics](https://github.com/kubernetes/ingress/blob/master/examples/customization/custom-vts-metrics/nginx/nginx-vts-metrics-conf.yaml).
1. Finally, [annotate](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) the NGINX Ingress deployment to be scraped by Prometheus using `prometheus.io/scrape: "true"` and `prometheus.io/port: "10254"`.

## Customizing

### PostgreSQL Database Support

In order to support applications that require a database,
[PostgreSQL][postgresql] is provisioned by default. Credentials to access the
database are preconfigured, but can be customized by setting the associated
[variables](#postgresql-variables). These credentials can be used for defining a
`DATABASE_URL` of the format:
`postgres://user:password@postgres-host:postgres-port/postgres-database`.

PostgreSQL provisioning can be disabled by creating a project variable
`POSTGRES_ENABLED` set to `false`.

#### PostgreSQL Variables

Any variables set at the project or group level will override variables set in
the CI/CD configuration.

1. `POSTGRES_ENABLED: "false"`: disable automatic deployment of PostgreSQL
1. `POSTGRES_USER: "my-user"`: use custom username for PostgreSQL
1. `POSTGRES_PASSWORD: "password"`: use custom password for PostgreSQL
1. `POSTGRES_DB: "my-database"`: use custom database name for PostgreSQL

### Custom buildpack

If the automatic buildpack detection fails for your project, or if you want to
use a custom buildpack, you can override the buildpack using a project variable
or a `.buildpack` file in your project:

- **Project variable** - Create a project variable `BUILDPACK_URL` with the URL
  of the buildpack to use.

- **`.buildpack` file** - Add a file in your project's repo called  `.buildpack`
  and add the URL of the buildpack to use on a line in the file. If you want to
  use multiple buildpacks, you can enter them in, one on each line

    >**Note:** Using multiple buildpacks may break Auto Test.

### Custom `Dockerfile`

If your project has a `Dockerfile` in the root of the project repo, Auto DevOps
will build a Docker image based on the Dockerfile rather than using buildpacks.
This can be much faster and result in smaller images, especially if your
Dockerfile is based on [Alpine](https://hub.docker.com/_/alpine/).

### Custom Helm Chart

Auto DevOps uses Helm to deploy your application to Kubernetes. You can override
the Helm chart used by bundling up a chart into your project repo or by
specifying a project variable.

**Bundled chart** - If your project has a `chart` directory with a `Chart.yaml`
file in it, Auto DevOps will detect the chart and use it instead of the default
chart. This can be a great way to control exactly how your application is
deployed.

**Project variable** - Create a project variable `AUTO_DEVOPS_CHART` with the
URL of a custom chart to use.

### Enable staging, canaries, and more with custom `.gitlab-ci.yml`

If you want to modify the CI/CD pipeline used by Auto DevOps, you can copy the
Auto DevOps template into your project's repo and edit as you see fit.

From your project home page, click on the `Set up CI` button, or click on the `+`
button and `New file` and pick `.gitlab-ci.yml` as the template type, or view an
existing `.gitlab-ci.yml` file. Then select "Auto DevOps" from the template
dropdown. You will then be able to edit or add any jobs needed.

For example, if you want deploys to go to a staging environment instead of
directly to a production environment, you can enable the `staging` job by
renaming `.staging` to `staging`. Then make sure to uncomment the `when` key of
the `production` job to turn it into a manual action instead of deploying
automatically.

## Currently supported languages

>**Note:**
Not all buildpacks support Auto Test yet, as it's a relatively new
enhancement. All of Heroku's [officially supported
languages](https://devcenter.heroku.com/articles/heroku-ci#currently-supported-languages)
support it, and some third-party buildpacks as well e.g., Go, Node, Java, PHP,
Python, Ruby, Gradle, Scala, and Elixir all support Auto Test, but notably the
multi-buildpack does not.

As of GitLab 10.0, the supported buildpacks are:

```
* heroku-buildpack-multi     v1.0.0
* heroku-buildpack-ruby      v168
* heroku-buildpack-nodejs    v99
* heroku-buildpack-clojure   v77
* heroku-buildpack-python    v99
* heroku-buildpack-java      v53
* heroku-buildpack-gradle    v23
* heroku-buildpack-scala     v78
* heroku-buildpack-play      v26
* heroku-buildpack-php       v122
* heroku-buildpack-go        v72
* heroku-buildpack-erlang    fa17af9
* buildpack-nginx            v8
```

## Private Project Support - Experimental

When a project has been marked as private, GitLab's [Container
Registry][container-registry] requires authentication when downloading
containers. Auto DevOps will automatically provide the required authentication
information to Kubernetes, allowing temporary access to the registry.
Authentication credentials will be valid while the pipeline is running, allowing
for a successful initial deployment.

After the pipeline completes, Kubernetes will no longer be able to access the
container registry. **Restarting a pod, scaling a service, or other actions which
require on-going access to the registry will fail**. On-going secure access is
planned for a subsequent release.

## Disable the banner instance wide

If an administrater would like to disable the banners on an instance level, this
feature can be disabled either through the console:

```basb
$ gitlab-rails console
[1] pry(main)> Feature.get(:auto_devops_banner_disabled).disable
=> true
```

Or through the HTTP API with the admin access token:

```
curl --data "value=true" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled
```

## Troubleshooting

- Auto Build and Auto Test may fail in detecting your language/framework. There
  may be no buildpack for your application, or your application may be missing the
  key files the buildpack is looking for. For example, for ruby apps, you must
  have a `Gemfile` to be properly detected, even though it is possible to write a
  Ruby app without a `Gemfile`. Try specifying a [custom
  buildpack](#custom-buildpack).
- Auto Test may fail because of a mismatch between testing frameworks. In this
  case, you may need to customize your `.gitlab-ci.yml` with your test commands.

[ce-37115]: https://gitlab.com/gitlab-org/gitlab-ce/issues/37115
[kubernetes-service]: ../../user/project/integrations/kubernetes.md
[docker-in-docker]: ../../docker/using_docker_build.md#use-docker-in-docker-executor
[review-app]: ../../ci/review_apps/index.md
[container-registry]: ../../user/project/container_registry.md
[postgresql]: https://www.postgresql.org/
