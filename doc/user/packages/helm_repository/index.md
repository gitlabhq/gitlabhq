---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Helm charts in the Package Registry **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18997) in GitLab 14.1.

Publish Helm packages in your project's Package Registry. Then install the
packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that Helm package manager
clients use, see the [Helm API documentation](../../../api/packages/helm.md).

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
       --form 'chart=@mychart-0.1.0.tgz' \
       --user <username>:<personal_access_token> \
       https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts
  ```

- With the [`helm-push`](https://github.com/chartmuseum/helm-push/#readme) plugin:

  ```shell
  helm repo add --username <username> --password <personal_access_token> project-1 https://gitlab.example.com/api/v4/projects/1/packages/helm/stable
  helm push mychart-0.1.0.tgz project-1
  ```

## Use CI/CD to publish a Helm package

To publish a Helm package automated through [GitLab CI/CD](../../../ci/index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example:

```yaml
image: curlimages/curl:latest
 
stages:
  - upload
 
upload:
  stage: upload
  script:
    - 'curl --request POST --user gitlab-ci-token:$CI_JOB_TOKEN --form "chart=@mychart-0.1.0.tgz" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/stable/charts"'
```

## Install a package

To install the latest version of a chart, use the following command:

```shell
helm repo add --username <username> --password <personal_access_token> project-1 https://gitlab.example.com/api/v4/projects/1/packages/helm/stable
helm install my-release project-1/mychart
```

If the repo has previously been added, you may need to run:

```shell
helm repo update
```

To update the Helm client with the most currently available charts.

See [Using Helm](https://helm.sh/docs/intro/using_helm/) for more information.
