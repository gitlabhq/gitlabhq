---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Helm charts in the Package Registry **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18997) in GitLab 14.1.

WARNING:
The Helm package registry for GitLab is under development and isn't ready for production use due to
limited functionality.

Publish Helm packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that Helm package manager
clients use, see the [Helm API documentation](../../../api/packages/helm.md).

## Enable the Helm repository feature

Helm repository support is still a work in progress. It's gated behind a feature flag that's
**disabled by default**. [GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to enable it.

To enable it:

```ruby
Feature.enable(:helm_packages)
```

To disable it:

```ruby
Feature.disable(:helm_packages)
```

## Build a Helm package

Creating a Helm package is documented [in the Helm documentation](https://helm.sh/docs/intro/using_helm/#creating-your-own-charts).

## Authenticate to the Helm repository

To authenticate to the Helm repository, you need either:

- A [personal access token](../../../api/index.md#personalproject-access-tokens).
- A [deploy token](../../project/deploy_tokens/index.md).
- A [CI/CD job token](../../../api/index.md#gitlab-cicd-job-token).

## Publish a package

Once built, a chart can be uploaded to the `stable` channel with `curl` or `helm-push`:

- With `curl`:

  ```shell
  curl --request POST \
       --form 'chart=@mychart.tgz' \
       --user <username>:<personal_access_token> \
       https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts
  ```

- With the [`helm-push`](https://github.com/chartmuseum/helm-push/#readme) plugin:

  ```shell
  helm repo add --username <username> --password <personal_access_token> project-1 https://gitlab.example.com/api/v4/projects/1/packages/helm/stable
  helm push mychart.tgz project-1
  ```

## Install a package

To install the latest version of a chart, use the following command:

```shell
helm repo add project-1 https://gitlab.example.com/api/v4/projects/1/packages/helm/stable
helm install my-release project-1/mychart
```

See [Using Helm](https://helm.sh/docs/intro/using_helm/) for more information.
