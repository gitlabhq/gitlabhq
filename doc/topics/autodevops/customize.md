# Customizing Auto DevOps

While [Auto DevOps](index.md) provides great defaults to get you started, you can customize
almost everything to fit your needs. Auto DevOps offers everything from custom
[buildpacks](#custom-buildpacks), to [Dockerfiles](#custom-dockerfile), and
[Helm charts](#custom-helm-chart). You can even copy the complete
[CI/CD configuration](#customizing-gitlab-ciyml) into your project to enable
staging and canary deployments, and more.

## Custom buildpacks

If the automatic buildpack detection fails for your project, or if you want to
use a custom buildpack, you can override the buildpack using a project variable
or a `.buildpacks` file in your project:

- **Project variable** - Create a project variable `BUILDPACK_URL` with the URL
  of the buildpack to use.
- **`.buildpacks` file** - Add a file in your project's repository called `.buildpacks`,
  and add the URL of the buildpack to use on a line in the file. If you want to
  use multiple buildpacks, enter one buildpack per line.

The buildpack URL can point to either a Git repository URL or a tarball URL.
For Git repositories, you can point to a specific Git reference (such as
commit SHA, tag name, or branch name) by appending `#<ref>` to the Git repository URL.
For example:

- The tag `v142`: `https://github.com/heroku/heroku-buildpack-ruby.git#v142`.
- The branch `mybranch`: `https://github.com/heroku/heroku-buildpack-ruby.git#mybranch`.
- The commit SHA `f97d8a8ab49`: `https://github.com/heroku/heroku-buildpack-ruby.git#f97d8a8ab49`.

### Multiple buildpacks

Using multiple buildpacks is not fully supported by Auto DevOps, because Auto Test
won't work when using the `.buildpacks` file. The buildpack
[heroku-buildpack-multi](https://github.com/heroku/heroku-buildpack-multi/), used
in the backend to parse the `.buildpacks` file, does not provide the necessary commands
`bin/test-compile` and `bin/test`.

If your goal is to use only a single custom buildpack, you should provide the project variable
`BUILDPACK_URL` instead.

## Custom `Dockerfile`

If your project has a `Dockerfile` in the root of the project repository, Auto DevOps
builds a Docker image based on the Dockerfile, rather than using buildpacks.
This can be much faster and result in smaller images, especially if your
Dockerfile is based on [Alpine](https://hub.docker.com/_/alpine/).

## Passing arguments to `docker build`

Arguments can be passed to the `docker build` command using the
`AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` project variable. For example, to build a
Docker image based on based on the `ruby:alpine` instead of the default `ruby:latest`:

1. Set `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS` to `--build-arg=RUBY_VERSION=alpine`.
1. Add the following to a custom `Dockerfile`:

   ```dockerfile
   ARG RUBY_VERSION=latest
   FROM ruby:$RUBY_VERSION

   # ... put your stuff here
   ```

NOTE: **Note:**
Use Base64 encoding if you need to pass complex values, such as newlines and
spaces. Left unencoded, complex values like these can cause escaping issues
due to how Auto DevOps uses the arguments.

CAUTION: **Warning:**
Avoid passing secrets as Docker build arguments if possible, as they may be
persisted in your image. See
[this discussion of best practices with secrets](https://github.com/moby/moby/issues/13490) for details.

## Forward CI variables to the build environment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25514) in GitLab 12.3, but available in versions 11.9 and above.

CI variables can be forwarded into the build environment using the
`AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` CI variable.
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

NOTE: **Note:**
When `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` is set, Auto DevOps
enables the experimental [Docker BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/)
feature to use the `--secret` flag.

## Custom Helm Chart

Auto DevOps uses [Helm](https://helm.sh/) to deploy your application to Kubernetes.
You can override the Helm chart used by bundling up a chart into your project
repository or by specifying a project variable:

- **Bundled chart** - If your project has a `./chart` directory with a `Chart.yaml`
  file in it, Auto DevOps will detect the chart and use it instead of the
  [default chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app), enabling
  you to control exactly how your application is deployed.
- **Project variable** - Create a [project variable](../../ci/variables/README.md#gitlab-cicd-environment-variables)
  `AUTO_DEVOPS_CHART` with the URL of a custom chart to use, or create two project
  variables: `AUTO_DEVOPS_CHART_REPOSITORY` with the URL of a custom chart repository,
  and `AUTO_DEVOPS_CHART` with the path to the chart.

## Customize values for Helm Chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30628) in GitLab 12.6, `.gitlab/auto-deploy-values.yaml` will be used by default for Helm upgrades.

You can override the default values in the `values.yaml` file in the
[default Helm chart](https://gitlab.com/gitlab-org/charts/auto-deploy-app) by either:

- Adding a file named `.gitlab/auto-deploy-values.yaml` to your repository, which is
  automatically used, if found.
- Adding a file with a different name or path to the repository, and setting the
  `HELM_UPGRADE_VALUES_FILE` [environment variable](#environment-variables) with
  the path and name.

NOTE: **Note:**
For GitLab 12.5 and earlier, use the `HELM_UPGRADE_EXTRA_ARGS` environment variable
to override the default chart values by setting `HELM_UPGRADE_EXTRA_ARGS` to `--values <my-values.yaml>`.

## Custom Helm chart per environment

You can specify the use of a custom Helm chart per environment by scoping the environment variable
to the desired environment. See [Limiting environment scopes of variables](../../ci/variables/README.md#limit-the-environment-scopes-of-environment-variables).

## Customizing `.gitlab-ci.yml`

Auto DevOps is completely customizable because the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
is just an implementation of a [`.gitlab-ci.yml`](../../ci/yaml/README.md) file,
and uses only features available to any implementation of `.gitlab-ci.yml`.

To modify the CI/CD pipeline used by Auto DevOps,
[`include` the template](../../ci/yaml/README.md#includetemplate), and customize
it as needed by adding a `.gitlab-ci.yml` file to the root of your repository
containing the following:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Add your changes, and your additions will be merged with the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
using the behavior described for [`include`](../../ci/yaml/README.md#include).

If you need to specifically remove a part of the file, you can also copy and paste the contents of the
[Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
into your project and edit it as needed.

## Customizing the Kubernetes namespace

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.

For clusters not managed by GitLab, you can customize the namespace in
`.gitlab-ci.yml` by specifying
[`environment:kubernetes:namespace`](../../ci/environments/index.md#configuring-kubernetes-deployments).
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

See the [Auto DevOps template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml) for information on available jobs.

CAUTION: **Deprecation**
Auto DevOps templates using the [`only`](../../ci/yaml/README.md#onlyexcept-basic) or
[`except`](../../ci/yaml/README.md#onlyexcept-basic) syntax will switch
to the [`rules`](../../ci/yaml/README.md#rules) syntax, starting in
[GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/213336).
If your `.gitlab-ci.yml` extends these Auto DevOps templates and override the `only` or
`except` keywords, you must migrate your templates to use the
[`rules`](../../ci/yaml/README.md#rules) syntax after the
base template is migrated to use the `rules` syntax.
For users who cannot migrate just yet, you can alternatively pin your templates to
the [GitLab 12.10 based templates](https://gitlab.com/gitlab-org/auto-devops-v12-10).

## PostgreSQL database support

To support applications requiring a database,
[PostgreSQL](https://www.postgresql.org/) is provisioned by default. The credentials to access
the database are preconfigured, but can be customized by setting the associated
[variables](#environment-variables). You can use these credentials to define a `DATABASE_URL`:

```yaml
postgres://user:password@postgres-host:postgres-port/postgres-database
```

### Upgrading PostgresSQL

CAUTION: **Deprecation**
The variable `AUTO_DEVOPS_POSTGRES_CHANNEL` that controls default provisioned
PostgreSQL was changed to `2` in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/210499).
To keep using the old PostgreSQL, set the `AUTO_DEVOPS_POSTGRES_CHANNEL` variable to
`1`.

The version of the chart used to provision PostgreSQL:

- Is 8.2.1 in GitLab 13.0 and later, but can be set back to 0.7.1 if needed.
- Can be set to from 0.7.1 to 8.2.1 in GitLab 12.9 and 12.10.
- Is 0.7.1 in GitLab 12.8 and earlier.

GitLab encourages users to [migrate their database](upgrading_postgresql.md)
to the newer PostgreSQL.

### Using external PostgreSQL database providers

While Auto DevOps provides out-of-the-box support for a PostgreSQL container for
production environments, for some use cases, it may not be sufficiently secure or
resilient, and you may want to use an external managed provider (such as
AWS Relational Database Service) for PostgreSQL.

You must define environment-scoped variables for `POSTGRES_ENABLED` and
`DATABASE_URL` in your project's CI/CD settings:

1. Disable the built-in PostgreSQL installation for the required environments using
   scoped [environment variables](../../ci/environments/index.md#scoping-environments-with-specs).
   For this use case, it's likely that only `production` will need to be added to this
   list. The built-in PostgreSQL setup for Review Apps and staging is sufficient.

   ![Auto Metrics](img/disable_postgres.png)

1. Define the `DATABASE_URL` CI variable as a scoped environment variable that will be
   available to your application. This should be a URL in the following format:

   ```yaml
   postgres://user:password@postgres-host:postgres-port/postgres-database
   ```

You must ensure that your Kubernetes cluster has network access to wherever
PostgreSQL is hosted.

## Environment variables

The following variables can be used for setting up the Auto DevOps domain,
providing a custom Helm chart, or scaling your application. PostgreSQL can
also be customized, and you can use a [custom buildpack](#custom-buildpacks).

### Build and deployment

The following table lists variables related to building and deploying
applications.

| **Variable**                            | **Description**                    |
|-----------------------------------------|------------------------------------|
| `ADDITIONAL_HOSTS`                      | Fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. |
| `<ENVIRONMENT>_ADDITIONAL_HOSTS`        | For a specific environment, the fully qualified domain names specified as a comma-separated list that are added to the Ingress hosts. This takes precedence over `ADDITIONAL_HOSTS`. |
| `AUTO_DEVOPS_ATOMIC_RELEASE`            | As of GitLab 13.0, Auto DevOps uses [`--atomic`](https://v2.helm.sh/docs/helm/#options-43) for Helm deployments by default. Set this variable to `false` to disable the use of `--atomic` |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_ENABLED`   | When set to a non-empty value and no `Dockerfile` is present, Auto Build builds your application using Cloud Native Buildpacks instead of Herokuish. [More details](stages.md#auto-build-using-cloud-native-buildpacks-beta). |
| `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`   | The builder used when building with Cloud Native Buildpacks. The default builder is `heroku/buildpacks:18`. [More details](stages.md#auto-build-using-cloud-native-buildpacks-beta). |
| `AUTO_DEVOPS_BUILD_IMAGE_EXTRA_ARGS`    | Extra arguments to be passed to the `docker build` command. Note that using quotes won't prevent word splitting. [More details](#passing-arguments-to-docker-build). |
| `AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES` | A [comma-separated list of CI variable names](#forward-ci-variables-to-the-build-environment) to be forwarded to the build environment (the buildpack builder or `docker build`). |
| `AUTO_DEVOPS_CHART`                     | Helm Chart used to deploy your apps. Defaults to the one [provided by GitLab](https://gitlab.com/gitlab-org/charts/auto-deploy-app). |
| `AUTO_DEVOPS_CHART_REPOSITORY`          | Helm Chart repository used to search for charts. Defaults to `https://charts.gitlab.io`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_NAME`     | From GitLab 11.11, used to set the name of the Helm repository. Defaults to `gitlab`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME` | From GitLab 11.11, used to set a username to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD`. |
| `AUTO_DEVOPS_CHART_REPOSITORY_PASSWORD` | From GitLab 11.11, used to set a password to connect to the Helm repository. Defaults to no credentials. Also set `AUTO_DEVOPS_CHART_REPOSITORY_USERNAME`. |
| `AUTO_DEVOPS_DEPLOY_DEBUG`              | From GitLab 13.1, if this variable is present, Helm will output debug logs. |
| `AUTO_DEVOPS_MODSECURITY_SEC_RULE_ENGINE` | From GitLab 12.5, used in combination with [ModSecurity feature flag](../../user/clusters/applications.md#web-application-firewall-modsecurity) to toggle [ModSecurity's `SecRuleEngine`](https://github.com/SpiderLabs/ModSecurity/wiki/Reference-Manual-(v2.x)#SecRuleEngine) behavior. Defaults to `DetectionOnly`. |
| `BUILDPACK_URL`                         | Buildpack's full URL. Can point to either [a Git repository URL or a tarball URL](#custom-buildpacks). |
| `CANARY_ENABLED`                        | From GitLab 11.0, used to define a [deploy policy for canary environments](#deploy-policy-for-canary-environments-premium). |
| `CANARY_PRODUCTION_REPLICAS`            | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md) in the production environment. Takes precedence over `CANARY_REPLICAS`. Defaults to 1. |
| `CANARY_REPLICAS`                       | Number of canary replicas to deploy for [Canary Deployments](../../user/project/canary_deployments.md). Defaults to 1. |
| `HELM_RELEASE_NAME`                     | From GitLab 12.1, allows the `helm` release name to be overridden. Can be used to assign unique release names when deploying multiple projects to a single namespace. |
| `HELM_UPGRADE_VALUES_FILE`              | From GitLab 12.6, allows the `helm upgrade` values file to be overridden. Defaults to `.gitlab/auto-deploy-values.yaml`. |
| `HELM_UPGRADE_EXTRA_ARGS`               | From GitLab 11.11, allows extra arguments in `helm` commands when deploying the application. Note that using quotes won't prevent word splitting. |
| `INCREMENTAL_ROLLOUT_MODE`              | From GitLab 11.4, if present, can be used to enable an [incremental rollout](#incremental-rollout-to-production-premium) of your application for the production environment. Set to `manual` for manual deployment jobs or `timed` for automatic rollout deployments with a 5 minute delay each one. |
| `K8S_SECRET_*`                          | From GitLab 11.7, any variable prefixed with [`K8S_SECRET_`](#application-secret-variables) will be made available by Auto DevOps as environment variables to the deployed application. |
| `KUBE_INGRESS_BASE_DOMAIN`              | From GitLab 11.8, can be used to set a domain per cluster. See [cluster domains](../../user/project/clusters/index.md#base-domain) for more information. |
| `PRODUCTION_REPLICAS`                   | Number of replicas to deploy in the production environment. Takes precedence over `REPLICAS` and defaults to 1. For zero downtime upgrades, set to 2 or greater. |
| `REPLICAS`                              | Number of replicas to deploy. Defaults to 1. |
| `ROLLOUT_RESOURCE_TYPE`                 | From GitLab 11.9, allows specification of the resource type being deployed when using a custom Helm chart. Default value is `deployment`. |
| `ROLLOUT_STATUS_DISABLED`               | From GitLab 12.0, used to disable rollout status check because it does not support all resource types, for example, `cronjob`. |
| `STAGING_ENABLED`                       | From GitLab 10.8, used to define a [deploy policy for staging and production environments](#deploy-policy-for-staging-and-production-environments). |

TIP: **Tip:**
After you set up your replica variables using a
[project variable](../../ci/variables/README.md#gitlab-cicd-environment-variables),
you can scale your application by redeploying it.

CAUTION: **Caution:**
You should *not* scale your application using Kubernetes directly. This can
cause confusion with Helm not detecting the change, and subsequent deploys with
Auto DevOps can undo your changes.

### Database

The following table lists variables related to the database.

| **Variable**                            | **Description**                    |
|-----------------------------------------|------------------------------------|
| `DB_INITIALIZE`                         | From GitLab 11.4, used to specify the command to run to initialize the application's PostgreSQL database. Runs inside the application pod. |
| `DB_MIGRATE`                            | From GitLab 11.4, used to specify the command to run to migrate the application's PostgreSQL database. Runs inside the application pod. |
| `POSTGRES_ENABLED`                      | Whether PostgreSQL is enabled. Defaults to `true`. Set to `false` to disable the automatic deployment of PostgreSQL. |
| `POSTGRES_USER`                         | The PostgreSQL user. Defaults to `user`. Set it to use a custom username. |
| `POSTGRES_PASSWORD`                     | The PostgreSQL password. Defaults to `testing-password`. Set it to use a custom password. |
| `POSTGRES_DB`                           | The PostgreSQL database name. Defaults to the value of [`$CI_ENVIRONMENT_SLUG`](../../ci/variables/README.md#predefined-environment-variables). Set it to use a custom database name. |
| `POSTGRES_VERSION`                      | Tag for the [`postgres` Docker image](https://hub.docker.com/_/postgres) to use. Defaults to `9.6.16` for tests and deployments as of GitLab 13.0 (previously `9.6.2`). If `AUTO_DEVOPS_POSTGRES_CHANNEL` is set to `1`, deployments will use the default version `9.6.2`. |

### Disable jobs

The following table lists variables used to disable jobs.

| **Variable**                            | **Description**                    |
|-----------------------------------------|------------------------------------|
| `CODE_QUALITY_DISABLED`                 | From GitLab 11.0, used to disable the `codequality` job. If the variable is present, the job won't be created. |
| `CONTAINER_SCANNING_DISABLED`           | From GitLab 11.0, used to disable the `sast:container` job. If the variable is present, the job won't be created. |
| `DAST_DISABLED`                         | From GitLab 11.0, used to disable the `dast` job. If the variable is present, the job won't be created. |
| `DEPENDENCY_SCANNING_DISABLED`          | From GitLab 11.0, used to disable the `dependency_scanning` job. If the variable is present, the job won't be created. |
| `LICENSE_MANAGEMENT_DISABLED`           | From GitLab 11.0, used to disable the `license_management` job. If the variable is present, the job won't be created. |
| `PERFORMANCE_DISABLED`                  | From GitLab 11.0, used to disable the `performance` job. If the variable is present, the job won't be created. |
| `REVIEW_DISABLED`                       | From GitLab 11.0, used to disable the `review` and the manual `review:stop` job. If the variable is present, these jobs won't be created. |
| `SAST_DISABLED`                         | From GitLab 11.0, used to disable the `sast` job. If the variable is present, the job won't be created. |
| `TEST_DISABLED`                         | From GitLab 11.0, used to disable the `test` job. If the variable is present, the job won't be created. |

### Application secret variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49056) in GitLab 11.7.

Some applications need to define secret variables that are accessible by the deployed
application. Auto DevOps detects variables starting with `K8S_SECRET_`, and makes
these prefixed variables available to the deployed application as environment variables.

To configure your application variables:

1. Go to your project's **{settings}** **Settings > CI/CD**, then expand the
   **Variables** section.

1. Create a CI/CD variable, ensuring the key is prefixed with
   `K8S_SECRET_`. For example, you can create a variable with key
   `K8S_SECRET_RAILS_MASTER_KEY`.

1. Run an Auto DevOps pipeline, either by manually creating a new
   pipeline or by pushing a code change to GitLab.

Auto DevOps pipelines will take your application secret variables to
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
create a new pipeline, you will find any running application pods won't have
the updated secrets. To update the secrets, either:

- Push a code update to GitLab to force the Kubernetes deployment to recreate pods.
- Manually delete running pods to cause Kubernetes to create new pods with updated
  secrets.

NOTE: **Note:**
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
  in the Helm Chart app definition. If not set, it won't be taken into account
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

TIP: **Tip:**
You can also set this inside your [project's settings](index.md#deployment-strategy).

The normal behavior of Auto DevOps is to use continuous deployment, pushing
automatically to the `production` environment every time a new pipeline is run
on the default branch. However, there are cases where you might want to use a
staging environment, and deploy to production manually. For this scenario, the
`STAGING_ENABLED` environment variable was introduced.

If you define `STAGING_ENABLED`, such as setting `STAGING_ENABLED` to
`1` as a CI/CD variable, then GitLab automatically deploys the application
to a `staging` environment, and creates a `production_manual` job for
you when you're ready to manually deploy to production.

### Deploy policy for canary environments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ci-yml/-/merge_requests/171) in GitLab 11.0.

You can use a [canary environment](../../user/project/canary_deployments.md) before
deploying any changes to production.

If you define `CANARY_ENABLED` in your project, such as setting `CANARY_ENABLED` to
`1` as a CI/CD variable, then two manual jobs are created:

- `canary` - Deploys the application to the canary environment.
- `production_manual` - Manually deploys the application to production.

### Incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5415) in GitLab 10.8.

TIP: **Tip:**
You can also set this inside your [project's settings](index.md#deployment-strategy).

When you're ready to deploy a new version of your app to production, you may want
to use an incremental rollout to replace just a few pods with the latest code to
check how the application is behaving before manually increasing the rollout up to 100%.

If `INCREMENTAL_ROLLOUT_MODE` is set to `manual` in your project, then instead
of the standard `production` job, 4 different
[manual jobs](../../ci/pipelines/index.md#add-manual-interaction-to-your-pipeline)
will be created:

1. `rollout 10%`
1. `rollout 25%`
1. `rollout 50%`
1. `rollout 100%`

The percentage is based on the `REPLICAS` variable, and defines the number of
pods you want to have for your deployment. If the value is `10`, and you run the
`10%` rollout job, there will be `1` new pod + `9` old ones.

To start a job, click the play icon (**{play}**) next to the job's name. You're not
required to go from `10%` to `100%`, you can jump to whatever job you want.
You can also scale down by running a lower percentage job, just before hitting
`100%`. Once you get to `100%`, you can't scale down, and you'd have to roll
back by redeploying the old version using the
[rollback button](../../ci/environments/index.md#retrying-and-rolling-back) in the
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
Before GitLab 11.4, the presence of the `INCREMENTAL_ROLLOUT_ENABLED` environment
variable enabled this feature. This configuration is deprecated, and will be
removed in the future.

### Timed incremental rollout to production **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7545) in GitLab 11.4.

TIP: **Tip:**
You can also set this inside your [project's settings](index.md#deployment-strategy).

This configuration is based on
[incremental rollout to production](#incremental-rollout-to-production-premium).

Everything behaves the same way, except:

- To enable it, set the `INCREMENTAL_ROLLOUT_MODE` variable to `timed`.
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
- A project, by explicitly [disabling Auto DevOps](index.md#enablingdisabling-auto-devops).
- An entire GitLab instance:
  - By an administrator running the following in a Rails console:

    ```ruby
    Feature.enable(:auto_devops_banner_disabled)
    ```

  - Through the REST API with an admin access token:

    ```shell
    curl --data "value=true" --header "PRIVATE-TOKEN: <personal_access_token>" https://gitlab.example.com/api/v4/features/auto_devops_banner_disabled
    ```
