---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Customize Auto DevOps
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can customize components of Auto DevOps to fit your needs. For example, you can:

- Add custom [buildpacks](#custom-buildpacks), [Dockerfiles](#custom-dockerfiles), and [Helm charts](#custom-helm-chart).
- Enable staging and canary deployments with a custom [CI/CD configuration](#customize-gitlab-ciyml).
- Extend Auto DevOps with the [GitLab API](#extend-auto-devops-with-the-api).

## Auto DevOps banner

When Auto DevOps is not enabled, a banner displays for users with at
least the Maintainer role:

![Auto DevOps banner](img/autodevops_banner_v12_6.png)

The banner can be disabled for:

- A user, when they dismiss it themselves.
- A project, by explicitly [disabling Auto DevOps](_index.md#enable-or-disable-auto-devops).
- An entire GitLab instance:
  - By an administrator running the following in a Rails console:

    ```ruby
    Feature.enable(:auto_devops_banner_disabled)
    ```

  - Through the REST API with an administrator access token:

    ```shell
    curl --data "value=true" --header "PRIVATE-TOKEN: <personal_access_token>" "https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled"
    ```

## Custom buildpacks

You can customize your buildpacks when either:

- The automatic buildpack detection fails for your project.
- You need more control over your build.

### Customize buildpacks with Cloud Native Buildpacks

Specify either:

- The CI/CD variable `BUILDPACK_URL` with any of [`pack`'s URI specification formats](https://buildpacks.io/docs/app-developer-guide/specify-buildpacks/).
- A [`project.toml` project descriptor](https://buildpacks.io/docs/app-developer-guide/using-project-descriptor/) with the buildpacks you would like to include.

### Multiple buildpacks

Because Auto Test cannot use the `.buildpacks` file, Auto DevOps does
not support multiple buildpacks. The buildpack
[heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/),
used in the backend to parse the `.buildpacks` file, does not provide
the necessary commands `bin/test-compile` and `bin/test`.

To use only a single custom buildpack, you should provide the project CI/CD variable
`BUILDPACK_URL` instead.

## Custom Dockerfiles

If you have a Dockerfile in the root of your project repository, Auto
DevOps builds a Docker image based on the Dockerfile. This can be
faster than using a buildpack. It can also result in smaller images,
especially if your Dockerfile is based on
[Alpine](https://hub.docker.com/_/alpine/).

If you set the `DOCKERFILE_PATH` CI/CD variable, Auto Build looks for a Dockerfile there
instead.

### Pass arguments to `docker build`

You can pass arguments to `docker build` with the
`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` project CI/CD variable.

For example, to build a Docker image based on based on the
`ruby:alpine` instead of the default `ruby:latest`:

1. Set `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` to `--build-arg=RUBY_VERSION=alpine`.
1. Add the following to a custom Dockerfile:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # ... put your stuff here
   ```

To pass complex values like spaces and newlines, use Base64 encoding.
Complex, unencoded values can cause issues with character escaping.

WARNING:
Do not pass secrets as Docker build arguments. Secrets might persist in your image. For more information, see
[this discussion of best practices with secrets](https://github.com/moby/moby/issues/13490).

## Custom container image

By default, [Auto Deploy](stages.md#auto-deploy) deploys a container image built and pushed to the GitLab registry by [Auto Build](stages.md#auto-build).
You can override this behavior by defining specific variables:

| Entry | Default | Can be overridden by |
| ----- | -----   | -----    |
| Image Path | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` for branch pipelines. `$CI_REGISTRY_IMAGE` for tag pipelines. | `$CI_APPLICATION_REPOSITORY` |
| Image Tag | `$CI_COMMIT_SHA` for branch pipelines. `$CI_COMMIT_TAG` for tag pipelines. | `$CI_APPLICATION_TAG` |

These variables also affect Auto Build and Auto Container Scanning. If you don't want to build and push an image to
`$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`, include only `Jobs/Deploy.gitlab-ci.yml`, or
[skip the `build` jobs](cicd_variables.md#job-skipping-variables).

If you use Auto Container Scanning and set a value for `$CI_APPLICATION_REPOSITORY`, then you should
also update `$CS_DEFAULT_BRANCH_IMAGE`. For more information, see
[Setting the default branch image](../../user/application_security/container_scanning/_index.md#setting-the-default-branch-image).

Here is an example setup in your `.gitlab-ci.yml`:

```yaml
variables:
  CI_APPLICATION_REPOSITORY: <your-image-repository>
  CI_APPLICATION_TAG: <the-tag>
```

## Extend Auto DevOps with the API

You can extend and manage your Auto DevOps configuration with GitLab APIs:

- [Use API calls to access settings](../../api/settings.md#available-settings),
  which include `auto_devops_enabled`, to enable Auto DevOps on projects by default.
- [Create a new project](../../api/projects.md#create-a-project).
- [Edit groups](../../api/groups.md#update-group-attributes).
- [Edit projects](../../api/projects.md#edit-a-project).

## Forward CI/CD variables to the build environment

To forward CI/CD variables to the build environment, add the names of the variables
you want to forward to the `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI/CD variable.
Separate multiple variables with commas.

For example, to forward the variables `CI_COMMIT_SHA` and `CI_ENVIRONMENT_NAME`:

```yaml
variables:
  AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: CI_COMMIT_SHA,CI_ENVIRONMENT_NAME
```

If you use buildpacks, the forwarded variables are available automatically as environment variables.

If you use a Dockerfile:

1. To activate the experimental Dockerfile syntax, add the following to your Dockerfile:

   ```dockerfile
   # syntax = docker/dockerfile:experimental
   ```

1. To make secrets available in any `RUN $COMMAND` in the `Dockerfile`, mount
   the secret file and source it before you run `$COMMAND`:

   ```dockerfile
   RUN --mount=type=secret,id=auto-devops-build-secrets . /run/secrets/auto-devops-build-secrets && $COMMAND
   ```

When `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` is set, Auto DevOps
enables the experimental [Docker BuildKit](https://docs.docker.com/build/buildkit/)
feature to use the `--secret` flag.

## Custom Helm chart

Auto DevOps uses [Helm](https://helm.sh/) to deploy your application to Kubernetes.
You can override the Helm chart used by bundling a chart in your project
repository or by specifying a project CI/CD variable:

- **Bundled chart** - If your project has a `./chart` directory with a `Chart.yaml`
  file in it, Auto DevOps detects the chart and uses it instead of the
  [default chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app).
- **Project variable** - Create a [project CI/CD variable](../../ci/variables/_index.md)
  `AUTO_DEVOPS_CHART` with the URL of a custom chart. You can also create five project
  variables:

  - `AUTO_DEVOPS_CHART_REPOSITORY` - The URL of a custom chart repository.
  - `AUTO_DEVOPS_CHART` - The path to the chart.
  - `AUTO_DEVOPS_CHART_REPOSITORY_INSECURE` - Set to a non-empty value to add a `--insecure-skip-tls-verify` argument to the Helm commands.
  - `AUTO_DEVOPS_CHART_CUSTOM_ONLY` - Set to a non-empty value to use only a custom chart. By default, the latest chart is downloaded from GitLab.
  - `AUTO_DEVOPS_CHART_VERSION` - The version of the deployment chart.

### Customize Helm chart values

To override the default values in the `values.yaml` file in the
[default Helm chart](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app), either:

- Add a file named `.gitlab/auto-deploy-values.yaml` to your repository. This file is used by default for Helm upgrades.
- Add a file with a different name or path to the repository. Set the
  `HELM_UPGRADE_VALUES_FILE` [CI/CD variable](cicd_variables.md) with the path and name of the file.

Some values cannot be overridden with the options above, but [this issue](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/issues/31) proposes to change this behavior.
To override settings like `replicaCount`, use the `REPLICAS` [build and deployment](cicd_variables.md#build-and-deployment-variables) CI/CD variable.

### Customize `helm upgrade`

The [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) uses the `helm upgrade` command.
To customize this command, pass it options with the `HELM_UPGRADE_EXTRA_ARGS` CI/CD variable.

For example, to disable pre- and post-upgrade hooks when `helm upgrade` runs:

```yaml
variables:
  HELM_UPGRADE_EXTRA_ARGS: --no-hooks
```

For a full list of options, see [the official `helm upgrade` documentation](https://helm.sh/docs/helm/helm_upgrade/).

### Limit a Helm chart to one environment

To limit a custom chart to one environment, add the environment scope to your CI/CD variables.
For more information, see [Limit the environment scope of CI/CD variables](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).

## Customize `.gitlab-ci.yml`

Auto DevOps is highly customizable because the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
is an implementation of a `.gitlab-ci.yml` file.
The template uses only features available to any implementation of `.gitlab-ci.yml`.

To add custom behaviors to the CI/CD pipeline used by Auto DevOps:

1. To the root of your repository, add a `.gitlab-ci.yml` file with the following contents:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
   ```

1. Add your changes to the `.gitlab-ci.yml` file. Your changes are merged with the Auto DevOps template. For more information about
   how `include` merges your changes, see [the `include` documentation](../../ci/yaml/_index.md#include).

To remove behaviors from the Auto DevOps pipeline:

1. Copy the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
   into your project.
1. Edit your copy of the template as needed.

### Use individual components of Auto DevOps

If you only require a subset of the features offered by Auto DevOps,
you can include individual Auto DevOps jobs in your own
`.gitlab-ci.yml`. Be sure to also define the stage required by each
job in your `.gitlab-ci.yml` file.

For example, to use [Auto Build](stages.md#auto-build), you can add the following to
your `.gitlab-ci.yml`:

```yaml
stages:
  - build

include:
  - template: Jobs/Build.gitlab-ci.yml
```

For a list of available jobs, see the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml).

## Use multiple Kubernetes clusters

See [Multiple Kubernetes clusters for Auto DevOps](multiple_clusters_auto_devops.md).

## Customizing the Kubernetes namespace

In GitLab 14.5 and earlier, you could use `environment:kubernetes:namespace`
to specify a namespace for the environment.
However, this feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8),
along with certificate-based integration.

You should now use the `KUBE_NAMESPACE` environment variable and
[limit its environment scope](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).

## Use images hosted in a local Docker registry

You can configure many Auto DevOps jobs to run in an [offline environment](../../user/application_security/offline_deployments/_index.md):

1. Copy the required Auto DevOps Docker images from Docker Hub and `registry.gitlab.com` to their local GitLab container registry.
1. After the images are hosted and available in a local registry, edit `.gitlab-ci.yml` to point to the locally hosted images. For example:

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

WARNING:
Provisioning a PostgreSQL database by default was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387766)
in GitLab 15.8 and will no longer be the default from 16.0. To enable database provisioning, set
the associated [CI/CD variable](cicd_variables.md#database-variables).

To support applications that require a database,
[PostgreSQL](https://www.postgresql.org/) is provisioned by default.
The credentials to access the database are preconfigured.

To customize the credentials, set the associated
[CI/CD variables](cicd_variables.md). You can also
define a custom `DATABASE_URL`:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### Upgrading PostgreSQL

GitLab uses chart version 8.2.1 to provision PostgreSQL by default.
You can set the version from 0.7.1 to 8.2.1.

If you use an older chart version, you should [migrate your database](upgrading_postgresql.md)
to the newer PostgreSQL.

The CI/CD variable `AUTO_DEVOPS_POSTGRES_CHANNEL` that controls default provisioned
PostgreSQL changed to `2` in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499).
To use the old PostgreSQL, set the `AUTO_DEVOPS_POSTGRES_CHANNEL` variable to
`1`.

### Customize values for PostgreSQL Helm Chart

To set custom values, do one of the following:

- Add a file named `.gitlab/auto-deploy-postgres-values.yaml` to your repository. If found, this
  file is used automatically. This file is used by default for PostgreSQL Helm upgrades.
- Add a file with a different name or path to the repository, and set the
  `POSTGRES_HELM_UPGRADE_VALUES_FILE` [environment variable](cicd_variables.md#database-variables) with the path
  and name.
- Set the `POSTGRES_HELM_UPGRADE_EXTRA_ARGS` [environment variable](cicd_variables.md#database-variables).

### Use external PostgreSQL database providers

Auto DevOps provides out-of-the-box support for a PostgreSQL container
for production environments. However, you might want to use an
external managed provider like AWS Relational Database Service.

To use an external managed provider:

1. Disable the built-in PostgreSQL installation for the required environments with
   environment-scoped [CI/CD variables](../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   Because the built-in PostgreSQL setup for review apps and staging is sufficient, you might only need to
   disable the installation for `production`.

   ![Auto Metrics](img/disable_postgres_v12_4.png)

1. Define the `DATABASE_URL` variable as an environment-scoped variable
   available to your application. This should be a URL in the following format:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

1. Ensure your Kubernetes cluster has network access to where PostgreSQL is hosted.
