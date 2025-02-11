---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm charts in the package registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Beta

WARNING:
The Helm chart registry for GitLab is under development and isn't ready for production use due to
limited functionality. This [epic](https://gitlab.com/groups/gitlab-org/-/epics/6366) details the remaining
work and timelines to make it production ready.

Publish Helm packages in your project's package registry. Then install the
packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that Helm package manager
clients use, see the [Helm API documentation](../../../api/packages/helm.md).

## Build a Helm package

Read more in the Helm documentation about these topics:

- [Create your own Helm charts](https://helm.sh/docs/intro/using_helm/#creating-your-own-charts)
- [Package a Helm chart into a chart archive](https://helm.sh/docs/helm/helm_package/#helm-package)

## Authenticate to the Helm repository

To authenticate to the Helm repository, you need either:

- A [personal access token](../../../api/rest/authentication.md#personalprojectgroup-access-tokens) with the scope set to `api`.
- A [deploy token](../../project/deploy_tokens/_index.md) with the scope set to `read_package_registry`, `write_package_registry`, or both.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).

## Publish a package

NOTE:
You can publish Helm charts with duplicate names or versions. If duplicates exist, GitLab always
returns the chart with the latest version.

Once built, a chart can be uploaded to the desired channel with `curl` or `helm cm-push`:

- With `curl`:

  ```shell
  curl --fail-with-body --request POST \
       --form 'chart=@mychart-0.1.0.tgz' \
       --user <username>:<access_token> \
       https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/api/<channel>/charts
  ```

  - `<username>`: the GitLab username or the deploy token username.
  - `<access_token>`: the personal access token or the deploy token.
  - `<project_id>`: the project ID (like `42`) or the
    [URL-encoded](../../../api/rest/_index.md#namespaced-paths) path of the project (like `group%2Fproject`).
  - `<channel>`: the name of the channel (like `stable`).

- With the [`helm cm-push`](https://github.com/chartmuseum/helm-push/#readme) plugin:

  ```shell
  helm repo add --username <username> --password <access_token> project-1 https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/<channel>
  helm cm-push mychart-0.1.0.tgz project-1
  ```

  - `<username>`: the GitLab username or the deploy token username.
  - `<access_token>`: the personal access token or the deploy token.
  - `<project_id>`: the project ID (like `42`).
  - `<channel>`: the name of the channel (like `stable`).

### Release channels

You can publish Helm charts to channels in GitLab. Channels are a method you can use to differentiate Helm chart repositories.
For example, you can use `stable` and `devel` as channels to allow users to add the `stable` repository while `devel` charts are isolated.

## Use CI/CD to publish a Helm package

To publish a Helm package automated through [GitLab CI/CD](../../../ci/_index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example:

```yaml
stages:
  - upload

upload:
  image: curlimages/curl:latest
  stage: upload
  script:
    - 'curl --fail-with-body --request POST --user gitlab-ci-token:$CI_JOB_TOKEN --form "chart=@mychart-0.1.0.tgz" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/<channel>/charts"'
```

- `<username>`: the GitLab username or the deploy token username.
- `<access_token>`: the personal access token or the deploy token.
- `<channel>`: the name of the channel (like `stable`).

## Install a package

NOTE:
When requesting a package, GitLab considers only the 1000 most recent packages created.
For each package, only the most recent package file is returned.

To install the latest version of a chart, use the following command:

```shell
helm repo add --username <username> --password <access_token> project-1 https://gitlab.example.com/api/v4/projects/<project_id>/packages/helm/<channel>
helm install my-release project-1/mychart
```

- `<username>`: the GitLab username or the deploy token username.
- `<access_token>`: the personal access token or the deploy token.
- `<project_id>`: the project ID (like `42`).
- `<channel>`: the name of the channel (like `stable`).

If the repository has previously been added, you may need to run:

```shell
helm repo update
```

To update the Helm client with the most currently available charts.

See [Using Helm](https://helm.sh/docs/intro/using_helm/) for more information.

## Troubleshooting

### The chart is not visible in the package registry after uploading

Check the [Sidekiq log](../../../administration/logs/_index.md#sidekiqlog)
for any related errors. If you see `Validation failed: Version is invalid`, it means that the
version in your `Chart.yaml` file does not follow [Helm Chart versioning specifications](https://helm.sh/docs/topics/charts/#charts-and-versioning).
To fix the error, use the correct version syntax and upload the chart again.

Support for providing better error messages for package processing errors in the UI is proposed in issue [330515](https://gitlab.com/gitlab-org/gitlab/-/issues/330515).

### `helm push` results in an error

Helm 3.7 introduced a breaking change for the `helm-push` plugin. You can update the
[Chart Museum plugin](https://github.com/chartmuseum/helm-push/#readme)
to use `helm cm-push`.
