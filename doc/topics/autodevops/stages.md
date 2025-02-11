---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Stages of Auto DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The following sections describe the stages of [Auto DevOps](_index.md).
Read them carefully to understand how each one works.

## Auto Build

NOTE:
Auto Build is not supported if Docker in Docker is not available for your GitLab Runners, like in OpenShift clusters. The OpenShift support in GitLab is tracked [in a dedicated epic](https://gitlab.com/groups/gitlab-org/-/epics/2068).

Auto Build creates a build of the application using an existing `Dockerfile` or
Heroku buildpacks. The resulting Docker image is pushed to the
[Container Registry](../../user/packages/container_registry/_index.md), and tagged
with the commit SHA or tag.

### Auto Build using a Dockerfile

If a project's repository contains a `Dockerfile` at its root, Auto Build uses
`docker build` to create a Docker image.

If you're also using Auto Review Apps and Auto Deploy, and you choose to provide
your own `Dockerfile`, you must either:

- Expose your application to port `5000`, as the
  [default Helm chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)
  assumes this port is available.
- Override the default values by
  [customizing the Auto Deploy Helm chart](customize.md#custom-helm-chart).

### Auto Build using Cloud Native Buildpacks

Auto Build builds an application using a project's `Dockerfile` if present. If no
`Dockerfile` is present, Auto Build builds your application using
[Cloud Native Buildpacks](https://buildpacks.io) to detect and build the
application into a Docker image. The feature uses the
[`pack` command](https://github.com/buildpacks/pack).
The default [builder](https://buildpacks.io/docs/for-app-developers/concepts/builder/)
is `heroku/buildpacks:22` but a different builder can be selected using
the CI/CD variable `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`.

Each buildpack requires your project's repository to contain certain files for
Auto Build to build your application successfully. The structure is
specific to the builder and buildpacks you have selected.
For example, when using the Heroku builder (the default), your application's
root directory must contain the appropriate file for your application's
language:

- For Python projects, a `Pipfile` or `requirements.txt` file.
- For Ruby projects, a `Gemfile` or `Gemfile.lock` file.

For the requirements of other languages and frameworks, read the
[Heroku buildpacks documentation](https://devcenter.heroku.com/articles/buildpacks#officially-supported-buildpacks).

NOTE:
Auto Test still uses Herokuish, as test suite detection is not
yet part of the Cloud Native Buildpack specification. For more information, see
[issue 212689](https://gitlab.com/gitlab-org/gitlab/-/issues/212689).

#### Mount volumes into the build container

The variable `BUILDPACK_VOLUMES` can be used to pass volume mount definitions to the
`pack` command. The mounts are passed to `pack build` using `--volume` arguments.
Each volume definition can include any of the capabilities provided by `build pack`
such as the host path, the target path, whether the volume is writable, and
one or more volume options.

Use a pipe `|` character to pass multiple volumes.
Each item from the list is passed to `build back` using a separate `--volume` argument.

In this example, three volumes are mounted in the container as `/etc/foo`, `/opt/foo`, and `/var/opt/foo`:

```yaml
buildjob:
  variables:
    BUILDPACK_VOLUMES: /mnt/1:/etc/foo:ro|/mnt/2:/opt/foo:ro|/mnt/3:/var/opt/foo:rw
```

Read more about defining volumes in the [`pack build` documentation](https://buildpacks.io/docs/for-platform-operators/how-to/integrate-ci/pack/cli/pack_build/).

### Moving from Herokuish to Cloud Native Buildpacks

Builds using Cloud Native Buildpacks support the same options as builds using
Herokuish, with the following caveats:

- The buildpack must be a Cloud Native Buildpack. A Heroku buildpack can be
  converted to a Cloud Native Buildpack using Heroku's
  [`cnb-shim`](https://github.com/heroku/cnb-shim).
- `BUILDPACK_URL` must be in a format
  [supported by `pack`](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/).
- The `/bin/herokuish` command is not present in the built image, and prefixing
  commands with `/bin/herokuish procfile exec` is no longer required (nor possible).
  Instead, custom commands should be prefixed with `/cnb/lifecycle/launcher`
  to receive the correct execution environment.

## Auto Test

Auto Test runs the appropriate tests for your application using
[Herokuish](https://github.com/gliderlabs/herokuish) and
[Heroku buildpacks](https://devcenter.heroku.com/articles/buildpacks) by analyzing
your project to detect the language and framework. Several languages and
frameworks are detected automatically, but if your language is not detected,
you may be able to create a [custom buildpack](customize.md#custom-buildpacks).
Check the [currently supported languages](#currently-supported-languages).

Auto Test uses tests you already have in your application. If there are no
tests, it's up to you to add them.

<!-- vale gitlab_base.Spelling = NO -->

NOTE:
Not all buildpacks supported by [Auto Build](#auto-build) are supported by Auto Test.
Auto Test uses [Herokuish](https://gitlab.com/gitlab-org/gitlab/-/issues/212689), *not*
Cloud Native Buildpacks, and only buildpacks that implement the
[Testpack API](https://devcenter.heroku.com/articles/testpack-api) are supported.

<!-- vale gitlab_base.Spelling = YES -->

### Currently supported languages

Not all buildpacks support Auto Test yet, as it's a relatively new
enhancement. All of Heroku's
[officially supported languages](https://devcenter.heroku.com/articles/heroku-ci#supported-languages)
support Auto Test. The languages supported by Heroku's Herokuish buildpacks all
support Auto Test, but notably the multi-buildpack does not.

The supported buildpacks are:

```plaintext
- heroku-buildpack-multi
- heroku-buildpack-ruby
- heroku-buildpack-nodejs
- heroku-buildpack-clojure
- heroku-buildpack-python
- heroku-buildpack-java
- heroku-buildpack-gradle
- heroku-buildpack-scala
- heroku-buildpack-play
- heroku-buildpack-php
- heroku-buildpack-go
- buildpack-nginx
```

If your application needs a buildpack that is not in the above list, you
might want to use a [custom buildpack](customize.md#custom-buildpacks).

## Auto Code Quality

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212499) from GitLab Starter to GitLab Free in 13.2.

Auto Code Quality uses the
[Code Quality image](https://gitlab.com/gitlab-org/ci-cd/codequality) to run
static analysis and other code checks on the current code. After creating the
report, it's uploaded as an artifact which you can later download and check
out. The merge request widget also displays any
[differences between the source and target branches](../../ci/testing/code_quality.md).

## Auto SAST

> - Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.
> - Select functionality made available in all tiers beginning in 13.1

Static Application Security Testing (SAST) runs static
analysis on the current code, and checks for potential security issues. The
Auto SAST stage requires [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 or above.

After creating the report, it's uploaded as an artifact which you can later
download and check out. The merge request widget also displays any security
warnings on [Ultimate](https://about.gitlab.com/pricing/) licenses.

For more information, see
[Static Application Security Testing (SAST)](../../user/application_security/sast/_index.md).

## Auto Secret Detection

Secret Detection uses the
[Secret Detection Docker image](https://gitlab.com/gitlab-org/security-products/analyzers/secrets) to run Secret Detection on the current code, and checks for leaked secrets.

After creating the report, it's uploaded as an artifact which you can later
download and evaluate. The merge request widget also displays any security
warnings on [Ultimate](https://about.gitlab.com/pricing/) licenses.

For more information, see [Secret Detection](../../user/application_security/secret_detection/_index.md).

## Auto Dependency Scanning

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Dependency Scanning runs analysis on the project's dependencies and checks for potential security issues.
The Auto Dependency Scanning stage is skipped on licenses other than
[Ultimate](https://about.gitlab.com/pricing/).

After creating the report, it's uploaded as an artifact which you can later download and
check out. The merge request widget displays any security warnings detected,

For more information, see
[Dependency Scanning](../../user/application_security/dependency_scanning/_index.md).

## Auto Container Scanning

Vulnerability static analysis for containers uses [Trivy](https://aquasecurity.github.io/trivy/latest/)
to check for potential security issues in Docker images. The Auto Container Scanning stage is
skipped on licenses other than [Ultimate](https://about.gitlab.com/pricing/).

After creating the report, it's uploaded as an artifact which you can later download and
check out. The merge request displays any detected security issues.

For more information, see
[Container Scanning](../../user/application_security/container_scanning/_index.md).

## Auto Review Apps

This is an optional step, since many projects don't have a Kubernetes cluster
available. If the [requirements](requirements.md) are not met, the job is
silently skipped.

[Review apps](../../ci/review_apps/_index.md) are temporary application environments based on the
branch's code so developers, designers, QA, product managers, and other
reviewers can actually see and interact with code changes as part of the review
process. Auto Review Apps create a Review App for each branch.

Auto Review Apps deploy your application to your Kubernetes cluster only. If no cluster
is available, no deployment occurs.

The Review App has a unique URL based on a combination of the project ID, the branch
or tag name, a unique number, and the Auto DevOps base domain, such as
`13083-review-project-branch-123456.example.com`. The merge request widget displays
a link to the Review App for easy discovery. When the branch or tag is deleted,
such as after merging a merge request, the Review App is also deleted.

Review apps are deployed using the
[auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app) chart with
Helm, which you can [customize](customize.md#custom-helm-chart). The application deploys
into the [Kubernetes namespace](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)
for the environment.

[Local Tiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

WARNING:
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old configuration.

## Auto DAST

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Dynamic Application Security Testing (DAST) uses the popular open source tool
[OWASP ZAProxy](https://github.com/zaproxy/zaproxy) to analyze the current code
and check for potential security issues. The Auto DAST stage is skipped on
licenses other than [Ultimate](https://about.gitlab.com/pricing/).

- On your default branch, DAST scans an application deployed specifically for that purpose
  unless you [override the target branch](#overriding-the-dast-target).
  The app is deleted after DAST has run.
- On feature branches, DAST scans the [review app](#auto-review-apps).

After the DAST scan completes, any security warnings are displayed
on the [Security Dashboard](../../user/application_security/security_dashboard/_index.md)
and the merge request widget.

For more information, see
[Dynamic Application Security Testing (DAST)](../../user/application_security/dast/_index.md).

### Overriding the DAST target

To use a custom target instead of the auto-deployed review apps,
set a `DAST_WEBSITE` CI/CD variable to the URL for DAST to scan.

WARNING:
If [DAST Full Scan](../../user/application_security/dast/browser/_index.md) is
enabled, GitLab strongly advises **not**
to set `DAST_WEBSITE` to any staging or production environment. DAST Full Scan
actively attacks the target, which can take down your application and lead to
data loss or corruption.

### Skipping Auto DAST

You can skip DAST jobs:

- On all branches by setting the `DAST_DISABLED` CI/CD variable to `"true"`.
- Only on the default branch by setting the `DAST_DISABLED_FOR_DEFAULT_BRANCH`
  variable to `"true"`.
- Only on feature branches by setting `REVIEW_DISABLED` variable to
  `"true"`. This also skips the Review App.

## Auto Browser Performance Testing

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Auto [Browser Performance Testing](../../ci/testing/browser_performance_testing.md)
measures the browser performance of a web page with the
[Sitespeed.io container](https://hub.docker.com/r/sitespeedio/sitespeed.io/),
creates a JSON report including the overall performance score for each page, and
uploads the report as an artifact. By default, it tests the root page of your Review and
Production environments. If you want to test additional URLs, add the paths to a
file named `.gitlab-urls.txt` in the root directory, one file per line. For example:

```plaintext
/
/features
/direction
```

Any browser performance differences between the source and target branches are also
[shown in the merge request widget](../../ci/testing/browser_performance_testing.md).

## Auto Load Performance Testing

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Auto [Load Performance Testing](../../ci/testing/load_performance_testing.md)
measures the server performance of an application with the
[k6 container](https://hub.docker.com/r/loadimpact/k6/),
creates a JSON report including several key result metrics, and
uploads the report as an artifact.

Some initial setup is required. A [k6](https://k6.io/) test needs to be
written that's tailored to your specific application. The test also needs to be
configured so it can pick up the environment's dynamic URL via a CI/CD variable.

Any load performance test result differences between the source and target branches are also
[shown in the merge request widget](../../user/project/merge_requests/widgets.md).

## Auto Deploy

You have the choice to deploy to [Amazon Elastic Compute Cloud (Amazon EC2)](https://aws.amazon.com/ec2/) in addition to a Kubernetes cluster.

Auto Deploy is an optional step for Auto DevOps. If the [requirements](requirements.md) are not met, the job is skipped.

After a branch or merge request is merged into the project's default branch, Auto Deploy deploys the application to a `production` environment in
the Kubernetes cluster, with a namespace based on the project name and unique
project ID, such as `project-4321`.

Auto Deploy does not include deployments to staging or canary environments by
default, but the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
contains job definitions for these tasks if you want to enable them.

You can use [CI/CD variables](cicd_variables.md) to automatically
scale your pod replicas, and to apply custom arguments to the Auto DevOps `helm upgrade`
commands. This is an easy way to
[customize the Auto Deploy Helm chart](customize.md#custom-helm-chart).

Helm uses the [auto-deploy-app](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)
chart to deploy the application into the
[Kubernetes namespace](../../user/project/clusters/deploy_to_cluster.md#deployment-variables)
for the environment.

[Local Tiller](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22036) is
used. Previous versions of GitLab had a Tiller installed in the project
namespace.

WARNING:
Your apps should *not* be manipulated outside of Helm (using Kubernetes directly).
This can cause confusion with Helm not detecting the change and subsequent
deploys with Auto DevOps can undo your changes. Also, if you change something
and want to undo it by deploying again, Helm may not detect that anything changed
in the first place, and thus not realize that it needs to re-apply the old configuration.

### GitLab deploy tokens

[GitLab Deploy Tokens](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token)
are created for internal and private projects when Auto DevOps is enabled, and the
Auto DevOps settings are saved. You can use a Deploy Token for permanent access to
the registry. After you manually revoke the GitLab Deploy Token, it isn't
automatically created.

If the GitLab Deploy Token can't be found, `CI_REGISTRY_PASSWORD` is
used.

NOTE:
`CI_REGISTRY_PASSWORD` is only valid during deployment. Kubernetes can
successfully pull the container image during deployment, but if the image must
be pulled again, such as after pod eviction, Kubernetes cannot do so
as it attempts to fetch the image using `CI_REGISTRY_PASSWORD`.

### Kubernetes 1.16+

WARNING:
The default value for the `deploymentApiVersion` setting was changed from
`extensions/v1beta` to `apps/v1`.

In Kubernetes 1.16 and later, a number of
[APIs were removed](https://kubernetes.io/blog/2019/07/18/api-deprecations-in-1-16/),
including support for `Deployment` in the `extensions/v1beta1` version.

To use Auto Deploy on a Kubernetes 1.16+ cluster:

1. If you are deploying your application for the first time in GitLab 13.0 or
   later, no configuration should be required.

1. If you have an in-cluster PostgreSQL database installed with
   `AUTO_DEVOPS_POSTGRES_CHANNEL` set to `1`, follow the
   [guide to upgrade PostgreSQL](upgrading_postgresql.md).

WARNING:
Follow the [guide to upgrading PostgreSQL](upgrading_postgresql.md)
to back up and restore your database before opting into version `2`.

### Migrations

You can configure database initialization and migrations for PostgreSQL to run
within the application pod by setting the project CI/CD variables `DB_INITIALIZE` and
`DB_MIGRATE`.

If present, `DB_INITIALIZE` is run as a shell command within an application pod
as a Helm post-install hook. As some applications can't run without a successful
database initialization step, GitLab deploys the first release without the
application deployment, and only the database initialization step. After the database
initialization completes, GitLab deploys a second release with the application
deployment as standard.

A post-install hook means that if any deploy succeeds,
`DB_INITIALIZE` isn't processed thereafter.

If present, `DB_MIGRATE` is run as a shell command within an application pod as
a Helm pre-upgrade hook.

For example, in a Rails application in an image built with
[Cloud Native Buildpacks](#auto-build-using-cloud-native-buildpacks):

- `DB_INITIALIZE` can be set to `RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:setup`
- `DB_MIGRATE` can be set to `RAILS_ENV=production /cnb/lifecycle/launcher bin/rails db:migrate`

Unless your repository contains a `Dockerfile`, your image is built with
Cloud Native Buildpacks, and you must prefix commands run in these images with
`/cnb/lifecycle/launcher` to replicate the environment where your application runs.

### Upgrade auto-deploy-app Chart

You can upgrade the auto-deploy-app chart by following the [upgrade guide](upgrading_auto_deploy_dependencies.md).

### Workers

Some web applications must run extra deployments for "worker processes". For
example, Rails applications commonly use separate worker processes
to run background tasks like sending emails.

The [default Helm chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app)
used in Auto Deploy
[has support for running worker processes](https://gitlab.com/gitlab-org/charts/auto-deploy-app/-/merge_requests/9).

To run a worker, you must ensure the worker can respond to
the standard health checks, which expect a successful HTTP response on port
`5000`. For [Sidekiq](https://github.com/mperham/sidekiq), you can use
the [`sidekiq_alive` gem](https://rubygems.org/gems/sidekiq_alive).

To work with Sidekiq, you must also ensure your deployments have
access to a Redis instance. Auto DevOps doesn't deploy this instance for you, so
you must:

- Maintain your own Redis instance.
- Set a CI/CD variable `K8S_SECRET_REDIS_URL`, which is the URL of this instance,
  to ensure it's passed into your deployments.

After configuring your worker to respond to health checks, run a Sidekiq
worker for your Rails application. You can enable workers by setting the
following in the [`.gitlab/auto-deploy-values.yaml` file](customize.md#customize-helm-chart-values):

```yaml
workers:
  sidekiq:
    replicaCount: 1
    command:
      - /cnb/lifecycle/launcher
      - sidekiq
    preStopCommand:
      - /cnb/lifecycle/launcher
      - sidekiqctl
      - quiet
    terminationGracePeriodSeconds: 60
```

### Running commands in the container

Unless your repository contains [a custom Dockerfile](#auto-build-using-a-dockerfile), applications built with [Auto Build](#auto-build)
might require commands to be wrapped as follows:

```shell
/cnb/lifecycle/launcher $COMMAND
```

Some of the reasons you may need to wrap commands:

- Attaching using `kubectl exec`.
- Using the GitLab [Web Terminal](../../ci/environments/_index.md#web-terminals-deprecated).

For example, to start a Rails console from the application root directory, run:

```shell
/cnb/lifecycle/launcher procfile exec bin/rails c
```

## Auto Code Intelligence

[GitLab code intelligence](../../user/project/code_intelligence.md) adds
code navigation features common to interactive development environments (IDE),
including type signatures, symbol documentation, and go-to definition. It's powered by
[LSIF](https://lsif.dev/) and available for Auto DevOps projects using Go language only.
GitLab plans to add support for more languages as more LSIF indexers become available.
You can follow the [code intelligence epic](https://gitlab.com/groups/gitlab-org/-/epics/4212)
for updates.

This stage is enabled by default. You can disable it by adding the
`CODE_INTELLIGENCE_DISABLED` CI/CD variable. Read more about
[disabling Auto DevOps jobs](../autodevops/cicd_variables.md#job-skipping-variables).
