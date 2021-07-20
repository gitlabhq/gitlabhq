---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting Auto DevOps **(FREE)**

The information in this documentation page describes common errors when using
Auto DevOps, and any available workarounds.

## Unable to select a buildpack

Auto Build and Auto Test may fail to detect your language or framework with the
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

## Pipeline that extends Auto DevOps with only / except fails

If your pipeline fails with the following message:

```plaintext
Found errors in your .gitlab-ci.yml:

  jobs:test config key may not be used with `rules`: only
```

This error appears when the included job's rules configuration has been overridden with the `only` or `except` syntax.
To fix this issue, you must either:

- Transition your `only/except` syntax to rules.
- (Temporarily) Pin your templates to the [GitLab 12.10 based templates](https://gitlab.com/gitlab-org/auto-devops-v12-10).

## Failure to create a Kubernetes namespace

Auto Deploy fails if GitLab can't create a Kubernetes namespace and
service account for your project. For help debugging this issue, see
[Troubleshooting failed deployment jobs](../../user/project/clusters/deploy_to_cluster.md#troubleshooting).

## Detected an existing PostgreSQL database

After upgrading to GitLab 13.0, you may encounter this message when deploying
with Auto DevOps:

```plaintext
Detected an existing PostgreSQL database installed on the
deprecated channel 1, but the current channel is set to 2. The default
channel changed to 2 in of GitLab 13.0.
[...]
```

Auto DevOps, by default, installs an in-cluster PostgreSQL database alongside
your application. The default installation method changed in GitLab 13.0, and
upgrading existing databases requires user involvement. The two installation
methods are:

- **channel 1 (deprecated):** Pulls in the database as a dependency of the associated
  Helm chart. Only supports Kubernetes versions up to version 1.15.
- **channel 2 (current):** Installs the database as an independent Helm chart. Required
  for using the in-cluster database feature with Kubernetes versions 1.16 and greater.

If you receive this error, you can do one of the following actions:

- You can *safely* ignore the warning and continue using the channel 1 PostgreSQL
  database by setting `AUTO_DEVOPS_POSTGRES_CHANNEL` to `1` and redeploying.

- You can delete the channel 1 PostgreSQL database and install a fresh channel 2
  database by setting `AUTO_DEVOPS_POSTGRES_DELETE_V1` to a non-empty value and
  redeploying.

  WARNING:
  Deleting the channel 1 PostgreSQL database permanently deletes the existing
  channel 1 database and all its data. See
  [Upgrading PostgreSQL](upgrading_postgresql.md)
  for more information on backing up and upgrading your database.

- If you are not using the in-cluster database, you can set
  `POSTGRES_ENABLED` to `false` and re-deploy. This option is especially relevant to
  users of *custom charts without the in-chart PostgreSQL dependency*.
  Database auto-detection is based on the `postgresql.enabled` Helm value for
  your release. This value is set based on the `POSTGRES_ENABLED` CI/CD variable
  and persisted by Helm, regardless of whether or not your chart uses the
  variable.

WARNING:
Setting `POSTGRES_ENABLED` to `false` permanently deletes any existing
channel 1 database for your environment.

## Error: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"

After upgrading your Kubernetes cluster to [v1.16+](stages.md#kubernetes-116),
you may encounter this message when deploying with Auto DevOps:

```plaintext
UPGRADE FAILED
Error: failed decoding reader into objects: unable to recognize "": no matches for kind "Deployment" in version "extensions/v1beta1"
```

This can occur if your current deployments on the environment namespace were deployed with a
deprecated/removed API that doesn't exist in Kubernetes v1.16+. For example,
if [your in-cluster PostgreSQL was installed in a legacy way](#detected-an-existing-postgresql-database),
the resource was created via the `extensions/v1beta1` API. However, the deployment resource
was moved to the `app/v1` API in v1.16.

To recover such outdated resources, you must convert the current deployments by mapping legacy APIs
to newer APIs. There is a helper tool called [`mapkubeapis`](https://github.com/hickeyma/helm-mapkubeapis)
that works for this problem. Follow these steps to use the tool in Auto DevOps:

1. Modify your `.gitlab-ci.yml` with:

   ```yaml
   include:
     - template: Auto-DevOps.gitlab-ci.yml
     - remote: https://gitlab.com/shinya.maeda/ci-templates/-/raw/master/map-deprecated-api.gitlab-ci.yml

   variables:
     HELM_VERSION_FOR_MAPKUBEAPIS: "v2" # If you're using auto-depoy-image v2 or above, please specify "v3".
   ```

1. Run the job `<environment-name>:map-deprecated-api`. Ensure that this job succeeds before moving
   to the next step. You should see something like the following output:

   ```shell
   2020/10/06 07:20:49 Found deprecated or removed Kubernetes API:
   "apiVersion: extensions/v1beta1
   kind: Deployment"
   Supported API equivalent:
   "apiVersion: apps/v1
   kind: Deployment"
   ```

1. Revert your `.gitlab-ci.yml` to the previous version. You no longer need to include the
   supplemental template `map-deprecated-api`.

1. Continue the deployments as usual.

## Error: error initializing: Looks like "https://kubernetes-charts.storage.googleapis.com" is not a valid chart repository or cannot be reached

As [announced in the official CNCF blog post](https://www.cncf.io/blog/2020/10/07/important-reminder-for-all-helm-users-stable-incubator-repos-are-deprecated-and-all-images-are-changing-location/),
the stable Helm chart repository was deprecated and removed on November 13th, 2020.
You may encounter this error after that date.

Some GitLab features had dependencies on the stable chart. To mitigate the impact, we changed them
to use new official repositories or the [Helm Stable Archive repository maintained by GitLab](https://gitlab.com/gitlab-org/cluster-integration/helm-stable-archive).
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

## Error: release .... failed: timed out waiting for the condition

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
[custom values to the Helm chart](customize.md#customize-values-for-helm-chart)
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
