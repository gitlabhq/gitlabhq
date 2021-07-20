---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Terraform module registry **(FREE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3221) in GitLab 14.0.

Publish Terraform modules in your project's Infrastructure Registry, then reference them using GitLab
as a Terraform module registry.

## Authenticate to the Terraform module registry

To authenticate to the Terraform module registry, you need either:

- A [personal access token](../../../api/index.md#personalproject-access-tokens) with at least `read_api` rights.
- A [CI/CD job token](../../../api/index.md#gitlab-cicd-job-token).

## Publish a Terraform Module

When you publish a Terraform Module, if it does not exist, it is created.

If a package with the same name and version already exists, it will not be created. It does not overwrite the existing package.

Prerequisites:

- You need to [authenticate with the API](../../../api/index.md#authentication). If authenticating with a deploy token, it must be configured with the `write_package_registry` scope.

```plaintext
PUT /projects/:id/packages/terraform/modules/:module_name/:module_system/:module_version/file
```

| Attribute          | Type            | Required | Description                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/index.md#namespaced-path-encoding).                                    |
| `module_name`      | string          | yes      | The package name. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), or hyphens (`-`).
| `module_system`    | string          | yes      | The package name. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), or hyphens (`-`).
| `module_version`   | string          | yes      | The package version. It must be valid according to the [Semantic Versioning Specification](https://semver.org/).

Provide the file content in the request body.

Example request using a personal access token:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --upload-file path/to/file.tgz \
     "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

Example response:

```json
{
  "message":"201 Created"
}
```

Example request using a deploy token:

```shell
curl --header "DEPLOY-TOKEN: <deploy_token>" \
     --upload-file path/to/file.tgz \
     "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/my-module/my-system/0.0.1/file"
```

Example response:

```json
{
  "message":"201 Created"
}
```

## Reference a Terraform Module

Prerequisites:

- You need to [authenticate with the API](../../../api/index.md#authentication). If authenticating with a personal access token, it must be configured with the `read_api` scope.

Authentication tokens (Job Token or Personal Access Token) can be provided for `terraform` in your `~/.terraformrc` file:

```plaintext
credentials "gitlab.com" {
  token = "<TOKEN>"
}
```

Where `gitlab.com` can be replaced with the hostname of your self-managed GitLab instance.

You can then reference your Terraform Module from a downstream Terraform project:

```plaintext
module "<module>" {
  source = "gitlab.com/<namespace>/<module_name>/<module_system>"
}
```

## Publish a Terraform module by using CI/CD

To work with Terraform modules in [GitLab CI/CD](../../../ci/index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example:

```yaml
image: curlimages/curl:latest

stages:
  - upload

upload:
  stage: upload
  script:
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file path/to/file.tgz "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/my-module/my-system/0.0.1/file"'
```

## Example projects

For examples of the Terraform module registry, check the projects below:

- The [_GitLab local file_ project](https://gitlab.com/mattkasa/gitlab-local-file) creates a minimal Terraform module and uploads it into the Terraform module registry using GitLab CI/CD.
- The [_Terraform module test_ project](https://gitlab.com/mattkasa/terraform-module-test) uses the module from the previous example.
