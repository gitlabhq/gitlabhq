---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting Auto DevOps
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

The information in this documentation page describes common errors when using
Auto DevOps, and any available workarounds.

## Trace Helm commands

Set the CI/CD variable `TRACE` to any value to make Helm commands produce verbose output. You can use this output to diagnose Auto DevOps deployment problems.

You can resolve some problems with Auto DevOps deployment by changing advanced Auto DevOps configuration variables. Read more about [customizing Auto DevOps CI/CD variables](cicd_variables.md).

## Unable to select a buildpack

Auto Test may fail to detect your language or framework with the
following error:

```plaintext
Step 5/11 : RUN /bin/herokuish buildpack build
 ---> Running in eb468cd46085
    -----> Unable to select a buildpack
The command '/bin/sh -c /bin/herokuish buildpack build' returned a non-zero code: 1
```

The following are possible reasons:

- Your application may be missing the key files the buildpack is looking for.
  Ruby applications require a `Gemfile` to be properly detected,
  even though it's possible to write a Ruby app without a `Gemfile`.
- No buildpack may exist for your application. Try specifying a
  [custom buildpack](customize.md#custom-buildpacks).

## Builder sunset error

Because of this [Heroku update](https://github.com/heroku/cnb-builder-images/pull/478), legacy shimmed `heroku/buildpacks:20` and `heroku/builder-classic:22` images now generate errors instead of warnings.

To resolve this issue, you should to migrate to the `heroku/builder:*` builder images. As a temporary workaround, you can also set an environment variable to skip errors.

### Migrating to `heroku/builder:*`

Before you migrate, you should read the release notes for the each [spec release](https://github.com/buildpacks/spec/releases) to determine potential breaking changes.
In this case, the relevant buildpack API versions are 0.6 and 0.7.
These breaking changes are especially relevant to buildpack maintainers.

For more information about the changes, you can also diff the [spec itself](https://github.com/buildpacks/spec/compare/buildpack/v0.5...buildpack/v0.7#files_bucket).

### Skipping errors

As a temporary workaround, you can skip the errors by setting and forwarding the `ALLOW_EOL_SHIMMED_BUILDER` environment variable:

```yaml
  variables:
    ALLOW_EOL_SHIMMED_BUILDER: "1"
    AUTO_DEVOPS_BUILD_IMAGE_FORWARDED_CI_VARIABLES: ALLOW_EOL_SHIMMED_BUILDER
```

## Pipeline that extends Auto DevOps with only / except fails

If your pipeline fails with the following message:

```plaintext
Unable to run pipeline

  jobs:test config key may not be used with `rules`: only
```

This error appears when the included job's rules configuration has been overridden with the `only` or `except` syntax.
To fix this issue, you must transition your `only/except` syntax to rules.

## Failure to create a Kubernetes namespace

Auto Deploy fails if GitLab can't create a Kubernetes namespace and
service account for your project. For help debugging this issue, see
[Troubleshooting failed deployment jobs](../../user/project/clusters/deploy_to_cluster.md#troubleshooting).

## Auto DevOps is automatically disabled for a project

If Auto DevOps is automatically disabled for a project, it may be due to the following reasons:

- The Auto DevOps setting has not been explicitly enabled in the [project](_index.md#per-project) itself. It is enabled only in the parent [group](_index.md#per-group) or its [instance](../../administration/settings/continuous_integration.md#configure-auto-devops-for-all-projects).
- The project has no history of successful Auto DevOps pipelines.
- An Auto DevOps pipeline failed.

To resolve this issue:

- Enable the Auto DevOps setting in the project.
- Fix errors that are breaking the pipeline so the pipeline reruns.

## Error: `unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"`

After upgrading your Kubernetes cluster to [v1.16+](stages.md#kubernetes-116),
you may encounter this message when deploying with Auto DevOps:

```plaintext
UPGRADE FAILED
Error: failed decoding reader into objects: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"
```

This can occur if your current deployments on the environment namespace were deployed with a
deprecated/removed API that doesn't exist in Kubernetes v1.16+.

To recover such outdated resources, you must convert the current deployments by mapping legacy APIs
to newer APIs.

## `Error: not a valid chart repository or cannot be reached`

As [announced in the official CNCF blog post](https://www.cncf.io/blog/2020/10/07/important-reminder-for-all-helm-users-stable-incubator-repos-are-deprecated-and-all-images-are-changing-location/),
the stable Helm chart repository was deprecated and removed on November 13th, 2020.
You may encounter this error after that date:

```plaintext
Error: error initializing: Looks like "https://kubernetes-charts.storage.googleapis.com"
is not a valid chart repository or cannot be reached
```

Some GitLab features had dependencies on the stable chart. To mitigate the impact, the dependencies
use new official repositories or the [Helm Stable Archive repository maintained by GitLab](https://gitlab.com/gitlab-org/cluster-integration/helm-stable-archive).
Auto Deploy contains [an example fix](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/merge_requests/127).

In Auto Deploy, `v1.0.6+` of `auto-deploy-image` no longer adds the deprecated stable repository to
the `helm` command. If you use a custom chart and it relies on the deprecated stable repository,
specify an older `auto-deploy-image` like this example:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

.auto-deploy:
  image: "registry.gitlab.com/gitlab-org/cluster-integration/auto-deploy-image:v1.0.5"
```

Keep in mind that this approach stops working when the stable repository is removed,
so you must eventually fix your custom chart.

To fix your custom chart:

1. In your chart directory, update the `repository` value in your `requirements.yaml` file from :

   ```yaml
   repository: "https://kubernetes-charts.storage.googleapis.com/"
   ```

   to:

   ```yaml
   repository: "https://charts.helm.sh/stable"
   ```

1. In your chart directory, run `helm dep update .` using the same Helm major version as Auto DevOps.
1. Commit the changes for the `requirements.yaml` file.
1. If you previously had a `requirements.lock` file, commit the changes to the file.
   If you did not previously have a `requirements.lock` file in your chart,
   you do not need to commit the new one. This file is optional, but when present,
   it's used to verify the integrity of the downloaded dependencies.

You can find more information in
[issue #263778, "Migrate PostgreSQL from stable Helm repository"](https://gitlab.com/gitlab-org/gitlab/-/issues/263778).

## `Error: release .... failed: timed out waiting for the condition`

When getting started with Auto DevOps, you may encounter this error when first
deploying your application:

```plaintext
INSTALL FAILED
PURGING CHART
Error: release staging failed: timed out waiting for the condition
```

This is most likely caused by a failed liveness (or readiness) probe attempted
during the deployment process. By default, these probes are run against the root
page of the deployed application on port 5000. If your application isn't configured
to serve anything at the root page, or is configured to run on a specific port
*other* than 5000, this check fails.

If it fails, you should see these failures in the events for the relevant
Kubernetes namespace. These events look like the following example:

```plaintext
LAST SEEN   TYPE      REASON                   OBJECT                                            MESSAGE
3m20s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Readiness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
3m32s       Warning   Unhealthy                pod/staging-85db88dcb6-rxd6g                      Liveness probe failed: Get http://10.192.0.6:5000/: dial tcp 10.192.0.6:5000: connect: connection refused
```

To change the port used for the liveness checks, pass
[custom values to the Helm chart](customize.md#customize-helm-chart-values)
used by Auto DevOps:

1. Create a directory and file at the root of your repository named `.gitlab/auto-deploy-values.yaml`.

1. Populate the file with the following content, replacing the port values with
   the actual port number your application is configured to use:

   ```yaml
   service:
     internalPort: <port_value>
     externalPort: <port_value>
   ```

1. Commit your changes.

After committing your changes, subsequent probes should use the newly-defined ports.
The page that's probed can also be changed by overriding the `livenessProbe.path`
and `readinessProbe.path` values (shown in the
[default `values.yaml`](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/blob/master/assets/auto-deploy-app/values.yaml)
file) in the same fashion.
