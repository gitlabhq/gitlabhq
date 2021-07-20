---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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

- The CI/CD variable `BUILDPACK_URL` according to [`pack`'s specifications](https://buildpacks.io/docs/app-developer-guide/specific-buildpacks/).
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

> Support for `DOCKERFILE_PATH` was [added in GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35662)

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

## Extend Auto DevOps with the API

You can extend and manage your Auto DevOps configuration with GitLab APIs:

- [Settings that can be accessed with API calls](../../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls),
  which include `auto_devops_enabled`, to enable Auto DevOps on projects by default.
- [Creating a new project](../../api/projects.md#create-project).
- [Editing groups](../../api/groups.md#update-group).
- [Editing projects](../../api/projects.md#edit-project).

## Forward CI/CD variables to the build environment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25514) in GitLab 12.3, but available in versions 11.9 and above.

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
enables the experimental [Docker BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/)
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
  `HELM_UPGRADE_VALUES_FILE` [CI/CD variable](#cicd-variables) with
  the path and name.

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

## Customizing the Kubernetes namespace

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.

For clusters not managed by GitLab, you can customize the namespace in
`.gitlab-ci.yml` by specifying
[`environment:kubernetes:namespace`](../../ci/environments/index.md#configure-kubernetes-deployments).
For example, the following configuration overrides the namespace used for
`production` deployments:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

production:
  environment:
    kubernetes:
      namespace: production
```

When deploying to a custom namespace with Auto DevOps, the service account
provided with the cluster needs at least the `edit` role within the namespace.

- If the service account can create namespaces, then the namespace can be created on-demand.
- Otherwise, the namespace must exist prior to deployment.

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
       - name: "$REGISTRY_URL/greg/docker/docker:20.10.6-dind"
         command: ['--tls=false', '--host=tcp://0.0.0.0:2375']
   ```

## PostgreSQL database support

To support applications requiring a database,
[PostgreSQL](https://www.postgresql.org/) is provisioned by default. The credentials to access
the database are preconfigured, but can be customized by setting the associated
[CI/CD variables](#cicd-variables). You can use these credentials to define a `DATABASE_URL`:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### Upgrading PostgresSQL

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
  `POSTGRES_HELM_UPGRADE_VALUES_FILE` [environment variable](#database) with the path
  and name.
- Set the `POSTGRES_HELM_UPGRADE_EXTRA_ARGS` [environment variable](#database).

### Using external PostgreSQL database providers

While Auto DevOps provides out-of-the-box support for a PostgreSQL container for
production environments, for some use cases, it may not be sufficiently secure or
resilient, and you may want to use an external managed provider (such as
AWS Relational Database Service) for PostgreSQL.

You must define environment-scoped CI/CD variables for `POSTGRES_ENABLED` and
`DATABASE_URL` in your project's CI/CD settings:

1. Disable the built-in PostgreSQL installation for the required environments using
   environment-scoped [CI/CD variables](../../ci/environments/index.md#scoping-environments-with-specs).
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

## CI/CD variables

The following variables can be used for setting up the Auto DevOps domain,
providing a custom Helm chart, or scaling your application. PostgreSQL can
also be customized, and you can use a [custom buildpack](#custom-buildpacks).

### Build and deployment

The following table lists CI/CD variables related to building and deploying
applications.

| **CI/CD Variable**                      | **Description**                    |
|-----------------------------------------|------------------------------------|
| `ADDITIONAL_HOSTS`                      | Fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. |
| `<ENVIRONMENT>_ADDITIONAL_HOSTS`        | For a specific environment, the fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. This takes precedence over `ADDITIONAL_HOSTS`. |
| `AUTO_DEVOPS_ATOMIC_RELEASE`            | As of GitLab 13.0, Auto DevOps uses [`--atomic`](https://v2.helm.sh/docs/helm/#options-43) for Helm deployments by default. Set this variable to `false` to disable the use of `--atomic` |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_ENABLED`   | Set to `false` to use Herokuish instead of Cloud Native Buildpacks with Auto Build. [More details](stages.md#auto-build-using-cloud-native-buildpacks). |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`   | The builder used when building with Cloud Native Buildpacks. The default builder is `heroku/buildpacks:18`. [More details](stages.md#auto-build-using-cloud-native-buildpacks). |
| `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`    | Extra arguments to be passed to the `docker build` command. Note that using quotes doesn't prevent word splitting. [More details](#passing-arguments-to-docker-build). |
| `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` | A [comma-separated list of CI/CD variable names](#forward-cicd-variables-to-the-build-environment) to be forwarded to the build environment (the buildpack builder or `docker build`). |
| `AUTO_DEVOPS_CHART`                     | Helm Chart used to deploy your apps. Defaults to the one [provided by GitLab](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app). |
| `AUTO_DEVOPS_CHART_REPOSITORY`          | Helm Chart repository used to search for charts. Defaults to `https://charts.gitlab.io`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_NAME`     | From GitLab 11.11, used to set the name of the Helm repository. Defaults to `gitlab`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME` | From GitLab 11.11, used to set a username to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD` | From GitLab 11.11, used to set a password to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME`. |
| `AUTO_DEVOPS_DEPLOY_DEBUG`              | From GitLab 13.1, if this variable is present, Helm outputs debug logs. |
| `AUTO_DEVOPS_ALLOW_TO_FORCE_DEPLOY_V<N>` | From [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image) v1.0.0, if this variable is present, a new major version of chart is forcibly deployed. For more information, see [Ignore warnings and continue deploying](upgrading_auto_deploy_dependencies.md#ignore-warnings-and-continue-deploying). |
| `BUILDPACK_URL`                         | Buildpack's full URL. [Must point to a URL supported by Pack or Herokuish](#custom-buildpacks). |
| `CANARY_ENABLED`                        | From GitLab 11.0, used to define a [deploy policy for canary environments](#deploy-policy-for-canary-environments). |
| `CANARY_PRODUCTION_REPLICAS`            | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md) in the production environment. Takes precedence over `CANARY_REPLICAS`. Defaults to 1. |
| `CANARY_REPLICAS`                       | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md). Defaults to 1. |
| `DOCKERFILE_PATH`                       | From GitLab 13.2, allows overriding the [default Dockerfile path for the build stage](#custom-dockerfile) |
| `HELM_RELEASE_NAME`                     | From GitLab 12.1, allows the `helm` release name to be overridden. Can be used to assign unique release names when deploying multiple projects to a single namespace. |
| `HELM_UPGRADE_VALUES_FILE`              | From GitLab 12.6, allows the `helm upgrade` values file to be overridden. Defaults to `.gitlab/auto-deploy-values.yaml`. |
| `HELM_UPGRADE_EXTRA_ARGS`               | From GitLab 11.11, allows extra options in `helm upgrade` commands when deploying the application. Note that using quotes doesn't prevent word splitting. |
| `INCREMENTAL_ROLLOUT_MODE`              | From GitLab 11.4, if present, can be used to enable an [incremental rollout](#incremental-rollout-to-production) of your application for the production environment. Set to `manual` for manual deployment jobs or `timed` for automatic rollout deployments with a 5 minute delay each one. |
| `K8S_SECRET_*`                          | From GitLab 11.7, any variable prefixed with [`K8S_SECRET_`](#application-secret-variables) is made available by Auto DevOps as environment variables to the deployed application. |
| `KUBE_INGRESS_BASE_DOMAIN`              | From GitLab 11.8, can be used to set a domain per cluster. See [cluster domains](../../user/project/clusters/gitlab_managed_clusters.md#base-domain) for more information. |
| `PRODUCTION_REPLICAS`                   | Number of replicas to deploy in the production environment. Takes precedence over `REPLICAS` and defaults to 1. For zero downtime upgrades, set to 2 or greater. |
| `REPLICAS`                              | Number of replicas to deploy. Defaults to 1. |
| `ROLLOUT_RESOURCE_TYPE`                 | From GitLab 11.9, allows specification of the resource type being deployed when using a custom Helm chart. Default value is `deployment`. |
| `ROLLOUT_STATUS_DISABLED`               | From GitLab 12.0, used to disable rollout status check because it does not support all resource types, for example, `cronjob`. |
| `STAGING_ENABLED`                       | From GitLab 10.8, used to define a [deploy policy for staging and production environments](#deploy-policy-for-staging-and-production-environments). |

NOTE:
After you set up your replica variables using a
[project CI/CD variable](../../ci/variables/index.md),
you can scale your application by redeploying it.

WARNING:
You should *not* scale your application using Kubernetes directly. This can
cause confusion with Helm not detecting the change, and subsequent deploys with
Auto DevOps can undo your changes.

### Database

The following table lists CI/CD variables related to the database.

| **CI/CD Variable**                            | **Description**                    |
|-----------------------------------------|------------------------------------|
| `DB_INITIALIZE`                         | From GitLab 11.4, used to specify the command to run to initialize the application's PostgreSQL database. Runs inside the application pod. |
| `DB_MIGRATE`                            | From GitLab 11.4, used to specify the command to run to migrate the application's PostgreSQL database. Runs inside the application pod. |
| `POSTGRES_ENABLED`                      | Whether PostgreSQL is enabled. Defaults to `true`. Set to `false` to disable the automatic deployment of PostgreSQL. |
| `POSTGRES_USER`                         | The PostgreSQL user. Defaults to `user`. Set it to use a custom username. |
| `POSTGRES_PASSWORD`                     | The PostgreSQL password. Defaults to `testing-password`. Set it to use a custom password. |
| `POSTGRES_DB`                           | The PostgreSQL database name. Defaults to the value of [`$CI_ENVIRONMENT_SLUG`](../../ci/variables/index.md#predefined-cicd-variables). Set it to use a custom database name. |
| `POSTGRES_VERSION`                      | Tag for the [`postgres` Docker image](https://hub.docker.com/_/postgres) to use. Defaults to `9.6.16` for tests and deployments as of GitLab 13.0 (previously `9.6.2`). If `AUTO_DEVOPS_POSTGRES_CHANNEL` is set to `1`, deployments uses the default version `9.6.2`. |
| `POSTGRES_HELM_UPGRADE_VALUES_FILE`     | In GitLab 13.8 and later, and when using [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md), this variable allows the `helm upgrade` values file for PostgreSQL to be overridden. Defaults to `.gitlab/auto-deploy-postgres-values.yaml`. |
| `POSTGRES_HELM_UPGRADE_EXTRA_ARGS`      | In GitLab 13.8 and later, and when using [auto-deploy-image v2](upgrading_auto_deploy_dependencies.md), this variable allows extra PostgreSQL options in `helm upgrade` commands when deploying the application. Note that using quotes doesn't prevent word splitting. |

### Disable jobs

The following table lists variables used to disable jobs.

| **Job Name**                           | **CI/CDVariable**               | **GitLab version**    | **Description** |
|----------------------------------------|---------------------------------|-----------------------|-----------------|
| `.fuzz_base`                           | `COVFUZZ_DISABLED`              | [From GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/34984) | [Read more](../../user/application_security/coverage_fuzzing/) about how `.fuzz_base` provide capability for your own jobs. If the variable is present, your jobs aren't created. |
| `apifuzzer_fuzz`                       | `API_FUZZING_DISABLED`          | [From GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39135) | If the variable is present, the job isn't created. |
| `build`                                | `BUILD_DISABLED`                |                       | If the variable is present, the job isn't created. |
| `build_artifact`                       | `BUILD_DISABLED`                |                       | If the variable is present, the job isn't created. |
| `bandit-sast`                          | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `brakeman-sast`                        | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `bundler-audit-dependency_scanning`    | `DEPENDENCY_SCANNING_DISABLED`  |                       | If the variable is present, the job isn't created. |
| `canary`                               | `CANARY_ENABLED`                |                       | This manual job is created if the variable is present. |
| `code_intelligence`                    | `CODE_INTELLIGENCE_DISABLED`    | From GitLab 13.6      | If the variable is present, the job isn't created. |
| `codequality`                          | `CODE_QUALITY_DISABLED`         | Until GitLab 11.0     | If the variable is present, the job isn't created. |
| `code_quality`                         | `CODE_QUALITY_DISABLED`         | [From GitLab 11.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/5773) | If the variable is present, the job isn't created. |
| `container_scanning`                   | `CONTAINER_SCANNING_DISABLED`   | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `dast`                                 | `DAST_DISABLED`                 | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `dast_environment_deploy`              | `DAST_DISABLED_FOR_DEFAULT_BRANCH` or `DAST_DISABLED` | [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17789) | If either variable is present, the job isn't created. |
| `dependency_scanning`                  | `DEPENDENCY_SCANNING_DISABLED`  | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `eslint-sast`                          | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `flawfinder-sast`                      | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `gemnasium-dependency_scanning`        | `DEPENDENCY_SCANNING_DISABLED`  |                       | If the variable is present, the job isn't created. |
| `gemnasium-maven-dependency_scanning`  | `DEPENDENCY_SCANNING_DISABLED`  |                       | If the variable is present, the job isn't created. |
| `gemnasium-python-dependency_scanning` | `DEPENDENCY_SCANNING_DISABLED`  |                       | If the variable is present, the job isn't created. |
| `gosec-sast`                           | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `kubesec-sast`                         | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `license_management`                   | `LICENSE_MANAGEMENT_DISABLED`   | GitLab 11.0 to 12.7   | If the variable is present, the job isn't created. Job deprecated [from GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22773) |
| `license_scanning`                     | `LICENSE_MANAGEMENT_DISABLED`   | [From GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22773) | If the variable is present, the job isn't created. |
| `load_performance`                     | `LOAD_PERFORMANCE_DISABLED`     | From GitLab 13.2      | If the variable is present, the job isn't created. |
| `nodejs-scan-sast`                     | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `performance`                          | `PERFORMANCE_DISABLED`          | GitLab 11.0 to GitLab 13.12 | Browser performance. If the variable is present, the job isn't created. Replaced by `browser_peformance`. |
| `browser_performance`                  | `BROWSER_PERFORMANCE_DISABLED`  | From GitLab 14.0      | Browser performance. If the variable is present, the job isn't created. Replaces `performance`. |
| `phpcs-security-audit-sast`            | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `pmd-apex-sast`                        | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `retire-js-dependency_scanning`        | `DEPENDENCY_SCANNING_DISABLED`  |                       | If the variable is present, the job isn't created. |
| `review`                               | `REVIEW_DISABLED`               | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `review:stop`                          | `REVIEW_DISABLED`               | From GitLab 11.0      | Manual job. If the variable is present, the job isn't created. |
| `sast`                                 | `SAST_DISABLED`                 | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `sast:container`                       | `CONTAINER_SCANNING_DISABLED`   | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `secret_detection`                     | `SECRET_DETECTION_DISABLED`     | From GitLab 13.1      | If the variable is present, the job isn't created. |
| `secret_detection_default_branch`      | `SECRET_DETECTION_DISABLED`     | [From GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22773) | If the variable is present, the job isn't created. |
| `security-code-scan-sast`              | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `secrets-sast`                         | `SAST_DISABLED`                 | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `sobelaw-sast`                         | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `stop_dast_environment`                | `DAST_DISABLED_FOR_DEFAULT_BRANCH` or `DAST_DISABLED` | [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17789) | If either variable is present, the job isn't created. |
| `spotbugs-sast`                        | `SAST_DISABLED`                 |                       | If the variable is present, the job isn't created. |
| `test`                                 | `TEST_DISABLED`                 | From GitLab 11.0      | If the variable is present, the job isn't created. |
| `staging`                              | `STAGING_ENABLED`               |                       | The job is created if the variable is present. |
| `stop_review`                          | `REVIEW_DISABLED`               |                       | If the variable is present, the job isn't created. |

### Application secret variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49056) in GitLab 11.7.

Some applications need to define secret variables that are accessible by the deployed
application. Auto DevOps detects CI/CD variables starting with `K8S_SECRET_`, and makes
these prefixed variables available to the deployed application as environment variables.

To configure your application variables:

1. Go to your project's **Settings > CI/CD**, then expand the
   **Variables** section.

1. Create a CI/CD variable, ensuring the key is prefixed with
   `K8S_SECRET_`. For example, you can create a variable with key
   `K8S_SECRET_RAILS_MASTER_KEY`.

1. Run an Auto DevOps pipeline, either by manually creating a new
   pipeline or by pushing a code change to GitLab.

Auto DevOps pipelines take your application secret variables to
populate a Kubernetes secret. This secret is unique per environment.
When deploying your application, the secret is loaded as environment
variables in the container running the application. Following the
example above, you can see the secret below containing the
`RAILS_MASTER_KEY` variable.

```shell
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

Environment variables are generally considered immutable in a Kubernetes pod.
If you update an application secret without changing any code, then manually
create a new pipeline, any running application pods don't receive
the updated secrets. To update the secrets, either:

- Push a code update to GitLab to force the Kubernetes deployment to recreate pods.
- Manually delete running pods to cause Kubernetes to create new pods with updated
  secrets.

Variables with multi-line values are not currently supported due to
limitations with the current Auto DevOps scripting environment.

### Advanced replica variables setup

Apart from the two replica-related variables for production mentioned above,
you can also use other variables for different environments.

The Kubernetes' label named `track`, GitLab CI/CD environment names, and the
replicas environment variable are combined into the format `TRACK_ENV_REPLICAS`,
enabling you to define your own variables for scaling the pod's replicas:

- `TRACK`: The capitalized value of the `track`
  [Kubernetes label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
  in the Helm Chart app definition. If not set, it isn't taken into account
  to the variable name.
- `ENV`: The capitalized environment name of the deploy job, set in
  `.gitlab-ci.yml`.

In the example below, the environment's name is `qa`, and it deploys the track
`foo`, which results in an environment variable named `FOO_QA_REPLICAS`:

```yaml
QA testing:
  stage: deploy
  environment:
    name: qa
  script:
    - deploy foo
```

The track `foo` being referenced must also be defined in the application's Helm chart, like:

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

### Deploy policy for staging and production environments

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ci-yml/-/merge_requests/160) in GitLab 10.8.

NOTE:
You can also set this inside your [project's settings](index.md#deployment-strategy).

The normal behavior of Auto DevOps is to use continuous deployment, pushing
automatically to the `production` environment every time a new pipeline is run
on the default branch. However, there are cases where you might want to use a
staging environment, and deploy to production manually. For this scenario, the
`STAGING_ENABLED` CI/CD variable was introduced.

If you define `STAGING_ENABLED` with a non-empty value, then GitLab automatically deploys the application
to a `staging` environment, and creates a `production_manual` job for
you when you're ready to manually deploy to production.

### Deploy policy for canary environments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ci-yml/-/merge_requests/171) in GitLab 11.0.

You can use a [canary environment](../../user/project/canary_deployments.md) before
deploying any changes to production.

If you define `CANARY_ENABLED` with a non-empty value, then two manual jobs are created:

- `canary` - Deploys the application to the canary environment.
- `production_manual` - Manually deploys the application to production.

### Incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5415) in GitLab 10.8.

NOTE:
You can also set this inside your [project's settings](index.md#deployment-strategy).

When you're ready to deploy a new version of your app to production, you may want
to use an incremental rollout to replace just a few pods with the latest code to
check how the application is behaving before manually increasing the rollout up to 100%.

If `INCREMENTAL_ROLLOUT_MODE` is set to `manual` in your project, then instead
of the standard `production` job, 4 different
[manual jobs](../../ci/pipelines/index.md#add-manual-interaction-to-your-pipeline)
are created:

1. `rollout 10%`
1. `rollout 25%`
1. `rollout 50%`
1. `rollout 100%`

The percentage is based on the `REPLICAS` CI/CD variable, and defines the number of
pods you want to have for your deployment. If the value is `10`, and you run the
`10%` rollout job, there is `1` new pod and `9` old ones.

To start a job, click the play icon (**{play}**) next to the job's name. You're not
required to go from `10%` to `100%`, you can jump to whatever job you want.
You can also scale down by running a lower percentage job, just before hitting
`100%`. Once you get to `100%`, you can't scale down, and you'd have to roll
back by redeploying the old version using the
[rollback button](../../ci/environments/index.md#retry-or-roll-back-a-deployment) in the
environment page.

Below, you can see how the pipeline appears if the rollout or staging
variables are defined.

Without `INCREMENTAL_ROLLOUT_MODE` and without `STAGING_ENABLED`:

![Staging and rollout disabled](img/rollout_staging_disabled.png)

Without `INCREMENTAL_ROLLOUT_MODE` and with `STAGING_ENABLED`:

![Staging enabled](img/staging_enabled.png)

With `INCREMENTAL_ROLLOUT_MODE` set to `manual` and without `STAGING_ENABLED`:

![Rollout enabled](img/rollout_enabled.png)

With `INCREMENTAL_ROLLOUT_MODE` set to `manual` and with `STAGING_ENABLED`

![Rollout and staging enabled](img/rollout_staging_enabled.png)

WARNING:
Before GitLab 11.4, the presence of the `INCREMENTAL_ROLLOUT_ENABLED` CI/CD variable
enabled this feature. This configuration is deprecated, and is scheduled to be
removed in the future.

### Timed incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7545) in GitLab 11.4.

NOTE:
You can also set this inside your [project's settings](index.md#deployment-strategy).

This configuration is based on
[incremental rollout to production](#incremental-rollout-to-production).

Everything behaves the same way, except:

- To enable it, set the `INCREMENTAL_ROLLOUT_MODE` CI/CD variable to `timed`.
- Instead of the standard `production` job, the following jobs are created with
  a 5 minute delay between each:

  1. `timed rollout 10%`
  1. `timed rollout 25%`
  1. `timed rollout 50%`
  1. `timed rollout 100%`

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

  - Through the REST API with an admin access token:

    ```shell
    curl --data "value=true" --header "PRIVATE-TOKEN: <personal_access_token>" "https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled"
    ```
