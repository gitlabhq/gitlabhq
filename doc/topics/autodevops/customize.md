---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Customizing Auto DevOps **(FREE)**

While [Auto DevOps](index.md) provides great defaults to get you started, you can customize
almost everything to fit your needs. Auto DevOps offers everything from custom
[buildpacks](#custom-buildpacks), to [Dockerfiles](#custom-dockerfile), and
[Helm charts](#custom-helm-chart). You can even copy the complete
[CI/CD configuration](#customizing-gitlab-ciyml) into your project to enable
staging and canary deployments,
[manage Auto DevOps with GitLab APIs](customize.md#extend-auto-devops-with-the-api), and more.

## Custom buildpacks

If the automatic buildpack detection fails for your project, or if you
need more control over your build, you can customize the buildpacks
used for the build.

### Custom buildpacks with Cloud Native Buildpacks

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28165) in GitLab 12.10.

Specify either:

- The CI/CD variable `BUILDPACK_URL` with any of [`pack`'s URI specification formats](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/).
- A [`project.toml` project descriptor](https://buildpacks.io/docs/app-developer-guide/using-project-descriptor/) with the buildpacks you would like to include.

### Custom buildpacks with Herokuish

Specify either:

- The CI/CD variable `BUILDPACK_URL`.
- A `.buildpacks` file at the root of your project, containing one buildpack URL per line.

The buildpack URL can point to either a Git repository URL or a tarball URL.
For Git repositories, you can point to a specific Git reference (such as
commit SHA, tag name, or branch name) by appending `#<ref>` to the Git repository URL.
For example:

- The tag `v142`: `https://github.com/heroku/heroku-buildpack-ruby.git#v142`.
- The branch `mybranch`: `https://github.com/heroku/heroku-buildpack-ruby.git#mybranch`.
- The commit SHA `f97d8a8ab49`: `https://github.com/heroku/heroku-buildpack-ruby.git#f97d8a8ab49`.

### Multiple buildpacks

Using multiple buildpacks is not fully supported by Auto DevOps, because Auto Test
can't use the `.buildpacks` file. The buildpack
[heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/), used
in the backend to parse the `.buildpacks` file, does not provide the necessary commands
`bin/test-compile` and `bin/test`.

If your goal is to use only a single custom buildpack, you should provide the project CI/CD variable
`BUILDPACK_URL` instead.

## Custom `Dockerfile`

> Support for `DOCKERFILE_PATH` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35662) in GitLab 13.2

If your project has a `Dockerfile` in the root of the project repository, Auto DevOps
builds a Docker image based on the Dockerfile, rather than using buildpacks.
This can be much faster and result in smaller images, especially if your
Dockerfile is based on [Alpine](https://hub.docker.com/_/alpine/).

If you set the `DOCKERFILE_PATH` CI/CD variable, Auto Build looks for a Dockerfile there
instead.

## Passing arguments to `docker build`

Arguments can be passed to the `docker build` command using the
`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` project CI/CD variable. For example, to build a
Docker image based on based on the `ruby:alpine` instead of the default `ruby:latest`:

1. Set `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` to `--build-arg=RUBY_VERSION=alpine`.
1. Add the following to a custom `Dockerfile`:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # ... put your stuff here
   ```

Use Base64 encoding if you need to pass complex values, such as newlines and
spaces. Left unencoded, complex values like these can cause escaping issues
due to how Auto DevOps uses the arguments.

WARNING:
Avoid passing secrets as Docker build arguments if possible, as they may be
persisted in your image. See
[this discussion of best practices with secrets](https://github.com/moby/moby/issues/13490) for details.

## Custom container image

By default, [Auto Deploy](stages.md#auto-deploy) deploys a container image built and pushed to the GitLab registry by [Auto Build](stages.md#auto-build).
You can override this behavior by defining specific variables:

| Entry | Default | Can be overridden by |
| ----- | -----   | -----    |
| Image Path | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` for branch pipelines. `$CI_REGISTRY_IMAGE` for tag pipelines. | `$CI_APPLICATION_REPOSITORY` |
| Image Tag | `$CI_COMMIT_SHA` for branch pipelines. `$CI_COMMIT_TAG` for tag pipelines. | `$CI_APPLICATION_TAG` |

These variables also affect Auto Build and Auto Container Scanning. If you don't want to build and push an image to
`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`, consider
including only `Jobs/Deploy.gitlab-ci.yml`, or [disabling the `build` jobs](cicd_variables.md#job-disabling-variables).

If you use Auto Container Scanning and set a value for `$CI_APPLICATION_REPOSITORY`, then you should
also update `$CS_DEFAULT_BRANCH_IMAGE`. See [Setting the default branch image](../../user/application_security/container_scanning/index.md#setting-the-default-branch-image)
for more details.

Here is an example setup in your `.gitlab-ci.yml`:

```yaml
variables:
  CI_APPLICATION_REPOSITORY: <your-image-repository>
  CI_APPLICATION_TAG: <the-tag>
```

## Extend Auto DevOps with the API

You can extend and manage your Auto DevOps configuration with GitLab APIs:

- [Settings that can be accessed with API calls](../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls),
  which include `auto_devops_enabled`, to enable Auto DevOps on projects by default.
- [Creating a new project](../../api/projects.md#create-project).
- [Editing groups](../../api/groups.md#update-group).
- [Editing projects](../../api/projects.md#edit-project).

## Forward CI/CD variables to the build environment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25514) in GitLab 12.3, but available in GitLab 12.0 and later.

CI/CD variables can be forwarded into the build environment using the
`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI/CD variable.
The forwarded variables should be specified by name in a comma-separated
list. For example, to forward the variables `CI_COMMIT_SHA` and
`CI_ENVIRONMENT_NAME`, set `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES`
to `CI_COMMIT_SHA,CI_ENVIRONMENT_NAME`.

- When using Buildpacks, the forwarded variables are available automatically
  as environment variables.
- When using a `Dockerfile`, the following additional steps are required:

  1. Activate the experimental `Dockerfile` syntax by adding the following code
     to the top of the file:

     ```dockerfile
     # syntax = docker/dockerfile:experimental
     ```

  1. To make secrets available in any `RUN $COMMAND` in the `Dockerfile`, mount
     the secret file and source it prior to running `$COMMAND`:

     ```dockerfile
     RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
     ```

When `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` is set, Auto DevOps
enables the experimental [Docker BuildKit](https://docs.docker.com/build/buildkit/)
feature to use the `--secret` flag.

## Custom Helm Chart

Auto DevOps uses [Helm](https://helm.sh/) to deploy your application to Kubernetes.
You can override the Helm chart used by bundling up a chart into your project
repository or by specifying a project CI/CD variable:

- **Bundled chart** - If your project has a `./chart` directory with a `Chart.yaml`
  file in it, Auto DevOps detects the chart and uses it instead of the
  [default chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app), enabling
  you to control exactly how your application is deployed.
- **Project variable** - Create a [project CI/CD variable](../../ci/variables/index.md)
  `AUTO_DEVOPS_CHART` with the URL of a custom chart to use, or create two project
  variables: `AUTO_DEVOPS_CHART_REPOSITORY` with the URL of a custom chart repository,
  and `AUTO_DEVOPS_CHART` with the path to the chart.

## Customize values for Helm Chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30628) in GitLab 12.6, `.gitlab/auto-deploy-values.yaml` is used by default for Helm upgrades.

You can override the default values in the `values.yaml` file in the
[default Helm chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app) by either:

- Adding a file named `.gitlab/auto-deploy-values.yaml` to your repository, which is
  automatically used, if found.
- Adding a file with a different name or path to the repository, and setting the
  `HELM_UPGRADE_VALUES_FILE` [CI/CD variable](cicd_variables.md) with
  the path and name.

Some values cannot be overridden with the options above. Settings like `replicaCount` should instead be overridden with the `REPLICAS`
[build and deployment](cicd_variables.md#build-and-deployment-variables) CI/CD variable. Follow [this issue](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/31) for more information.

NOTE:
For GitLab 12.5 and earlier, use the `HELM_UPGRADE_EXTRA_ARGS` variable
to override the default chart values by setting `HELM_UPGRADE_EXTRA_ARGS` to `--values <my-values.yaml>`.

## Customize the `helm upgrade` command

You can customize the `helm upgrade` command used in the [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)
by passing options to the command with the `HELM_UPGRADE_EXTRA_ARGS` CI/CD variable.
For example, set the value of `HELM_UPGRADE_EXTRA_ARGS` to `--no-hooks` to disable
pre-upgrade and post-upgrade hooks when the command is executed.

See [the official documentation](https://helm.sh/docs/helm/helm_upgrade/) for the full
list of options.

## Custom Helm chart per environment

You can specify the use of a custom Helm chart per environment by scoping the CI/CD variable
to the desired environment. See [Limit environment scope of CI/CD variables](../../ci/variables/index.md#limit-the-environment-scope-of-a-cicd-variable).

## Customizing `.gitlab-ci.yml`

Auto DevOps is completely customizable because the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
is just an implementation of a [`.gitlab-ci.yml`](../../ci/yaml/index.md) file,
and uses only features available to any implementation of `.gitlab-ci.yml`.

To modify the CI/CD pipeline used by Auto DevOps,
[`include` the template](../../ci/yaml/index.md#includetemplate), and customize
it as needed by adding a `.gitlab-ci.yml` file to the root of your repository
containing the following:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Add your changes, and your additions are merged with the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
using the behavior described for [`include`](../../ci/yaml/index.md#include).

If you need to specifically remove a part of the file, you can also copy and paste the contents of the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
into your project and edit it as needed.

## Use multiple Kubernetes clusters

See [Multiple Kubernetes clusters for Auto DevOps](multiple_clusters_auto_devops.md).

## Customizing the Kubernetes namespace

In GitLab 14.5 and earlier, you could use `environment:kubernetes:namespace`
to specify a namespace for the environment.
However, this feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8),
along with certificate-based integration.

You should now use the `KUBE_NAMESPACE` environment variable and
[limit the environments it is available for](../../ci/environments/index.md#scope-environments-with-specs).

## Using components of Auto DevOps

If you only require a subset of the features offered by Auto DevOps, you can include
individual Auto DevOps jobs into your own `.gitlab-ci.yml`. Each component job relies
on a stage that should be defined in the `.gitlab-ci.yml` that includes the template.

For example, to make use of [Auto Build](stages.md#auto-build), you can add the following to
your `.gitlab-ci.yml`:

```yaml
stages:
  - build

include:
  - template: Jobs/Build.gitlab-ci.yml
```

See the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml) for information on available jobs.

WARNING:
Auto DevOps templates using the [`only`](../../ci/yaml/index.md#only--except) or
[`except`](../../ci/yaml/index.md#only--except) syntax have switched
to the [`rules`](../../ci/yaml/index.md#rules) syntax, starting in
[GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/213336).
If your `.gitlab-ci.yml` extends these Auto DevOps templates and override the `only` or
`except` keywords, you must migrate your templates to use the
[`rules`](../../ci/yaml/index.md#rules) syntax after the
base template is migrated to use the `rules` syntax.
For users who cannot migrate just yet, you can alternatively pin your templates to
the [GitLab 12.10 based templates](https://gitlab.com/gitlab-org/auto-devops-v12-10).

## Use images hosted in a local Docker registry

You can configure many Auto DevOps jobs to run in an [offline environment](../../user/application_security/offline_deployments/index.md):

1. Copy the required Auto DevOps Docker images from Docker Hub and `registry.gitlab.com` to their local GitLab container registry.
1. After the images are hosted and available in a local registry, edit `.gitlab-ci.yml` to point to the locally-hosted images. For example:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml

   variables:
     REGISTRY_URL: "registry.gitlab.example"

   build:
     image: "$REGISTRY_URL/docker/auto-build-image:v0.6.0"
     services:
       - name: "$REGISTRY_URL/greg/docker/docker:20.10.16-dind"
         command: ['--tls=false', '--host=tcp://0.0.0.0:2375']
   ```

## PostgreSQL database support

To support applications requiring a database,
[PostgreSQL](https://www.postgresql.org/) is provisioned by default. The credentials to access
the database are preconfigured, but can be customized by setting the associated
[CI/CD variables](cicd_variables.md). You can use these credentials to define a `DATABASE_URL`:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### Upgrading PostgreSQL

WARNING:
The CI/CD variable `AUTO_DEVOPS_POSTGRES_CHANNEL` that controls default provisioned
PostgreSQL was changed to `2` in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499).
To keep using the old PostgreSQL, set the `AUTO_DEVOPS_POSTGRES_CHANNEL` variable to
`1`.

The version of the chart used to provision PostgreSQL:

- Is 8.2.1 in GitLab 13.0 and later, but can be set back to 0.7.1 if needed.
- Can be set to from 0.7.1 to 8.2.1 in GitLab 12.9 and 12.10.
- Is 0.7.1 in GitLab 12.8 and earlier.

GitLab encourages users to [migrate their database](upgrading_postgresql.md)
to the newer PostgreSQL.

### Customize values for PostgreSQL Helm Chart

> [Introduced](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/113) in auto-deploy-image v2, in GitLab 13.8.

To set custom values, do one of the following:

- Add a file named `.gitlab/auto-deploy-postgres-values.yaml` to your repository. If found, this
  file is used automatically. This file is used by default for PostgreSQL Helm upgrades.
- Add a file with a different name or path to the repository, and set the
  `POSTGRES_HELM_UPGRADE_VALUES_FILE` [environment variable](cicd_variables.md#database-variables) with the path
  and name.
- Set the `POSTGRES_HELM_UPGRADE_EXTRA_ARGS` [environment variable](cicd_variables.md#database-variables).

### Using external PostgreSQL database providers

While Auto DevOps provides out-of-the-box support for a PostgreSQL container for
production environments, for some use cases, it may not be sufficiently secure or
resilient, and you may want to use an external managed provider (such as
AWS Relational Database Service) for PostgreSQL.

You must define environment-scoped CI/CD variables for `POSTGRES_ENABLED` and
`DATABASE_URL` in your project's CI/CD settings:

1. Disable the built-in PostgreSQL installation for the required environments using
   environment-scoped [CI/CD variables](../../ci/environments/index.md#scope-environments-with-specs).
   For this use case, it's likely that only `production` must be added to this
   list. The built-in PostgreSQL setup for Review Apps and staging is sufficient.

   ![Auto Metrics](img/disable_postgres.png)

1. Define the `DATABASE_URL` variable as an environment-scoped variable that is
   available to your application. This should be a URL in the following format:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

You must ensure that your Kubernetes cluster has network access to wherever
PostgreSQL is hosted.

## Auto DevOps banner

The following Auto DevOps banner displays for users with Maintainer or greater
permissions on new projects when Auto DevOps is not enabled:

![Auto DevOps banner](img/autodevops_banner_v12_6.png)

The banner can be disabled for:

- A user, when they dismiss it themselves.
- A project, by explicitly [disabling Auto DevOps](index.md#enable-or-disable-auto-devops).
- An entire GitLab instance:
  - By an administrator running the following in a Rails console:

    ```ruby
    Feature.enable(:auto_devops_banner_disabled)
    ```

  - Through the REST API with an administrator access token:

    ```shell
    curl --data "value=true" --header "PRIVATE-TOKEN: <personal_access_token>" "https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled"
    ```
