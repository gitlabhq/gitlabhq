---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Terraform module registry **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3221) in GitLab 14.0.

Publish Terraform modules in your project's Infrastructure Registry, then reference them using GitLab
as a Terraform module registry.

## Authenticate to the Terraform module registry

To authenticate to the Terraform module registry, you need either:

- A [personal access token](../../../api/rest/index.md#personalprojectgroup-access-tokens) with at least `read_api` rights.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).

## Publish a Terraform Module

When you publish a Terraform Module, if it does not exist, it is created.

Prerequisites:

- The package name and version [must be unique in the top-level namespace](../infrastructure_registry/index.md#how-module-resolution-works).
- Your project and group names must not include a dot (`.`). For example, `source = "gitlab.example.com/my.group/project.name"`.
- You must [authenticate with the API](../../../api/rest/index.md#authentication). If authenticating with a deploy token, it must be configured with the `write_package_registry` scope.
- The name of a module [must be unique within the scope of its group](../infrastructure_registry/index.md#how-module-resolution-works), otherwise an
  [error occurs](#troubleshooting).

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| Attribute          | Type            | Required | Description                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/rest/index.md#namespaced-path-encoding).                                    |
| `module-name`      | string          | yes      | The package name. **Supported syntax**: One to 64 ASCII characters, including lowercase letters (a-z), digits (0-9), and hyphens (`-`).
| `module-system`    | string          | yes      | The package system. **Supported syntax**: One to 64 ASCII characters, including lowercase letters (a-z), digits (0-9), and hyphens (`-`). More information can be found in the [Terraform Module Registry Protocol documentation](https://www.terraform.io/internals/module-registry-protocol).
| `module-version`   | string          | yes      | The package version. It must be valid according to the [Semantic Versioning Specification](https://semver.org/).

Provide the file content in the request body.

As the following example shows, requests must end with `/file`.
If you send a request ending with something else, it results in a 404
error `{"error":"404 Not Found"}`.

Example request using a personal access token:

```shell
curl --fail-with-body --header "PRIVATE-TOKEN: <your_access_token>" \
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
curl --fail-with-body --header "DEPLOY-TOKEN: <deploy_token>" \
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

- You need to [authenticate with the API](../../../api/rest/index.md#authentication). If authenticating with a personal access token, it must be configured with the `read_api` scope.

Authentication tokens (Job Token or Personal Access Token) can be provided for `terraform` in your `~/.terraformrc` file:

```plaintext
credentials "gitlab.com" {
  token = "<TOKEN>"
}
```

Where `gitlab.com` can be replaced with the hostname of your self-managed GitLab instance.

You can then refer to your Terraform Module from a downstream Terraform project:

```plaintext
module "<module>" {
  source = "gitlab.com/<namespace>/<module-name>/<module-system>"
}
```

Where `<namespace>` is the [namespace](../../../user/namespace/index.md) of the Terraform module registry.

## Publish a Terraform module by using CI/CD

To work with Terraform modules in [GitLab CI/CD](../../../ci/index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example, this job uploads a new module for the `local` [system provider](https://registry.terraform.io/browse/providers) and uses the module version from the Git commit tag:

```yaml
stages:
  - upload

upload:
  stage: upload
  image: curlimages/curl:latest
  variables:
    TERRAFORM_MODULE_DIR: ${CI_PROJECT_DIR} # The path to your Terraform module
    TERRAFORM_MODULE_NAME: ${CI_PROJECT_NAME} # The name of your Terraform module
    TERRAFORM_MODULE_SYSTEM: local # The system or provider your Terraform module targets (ex. local, aws, google)
    TERRAFORM_MODULE_VERSION: ${CI_COMMIT_TAG} # Tag commits with SemVer for the version of your Terraform module to be published
  script:
    - TERRAFORM_MODULE_NAME=$(echo "${TERRAFORM_MODULE_NAME}" | tr " _" -) # module-name must not have spaces or underscores, so translate them to hyphens
    - tar -vczf ${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz -C ${TERRAFORM_MODULE_DIR} --exclude=./.git .
    - 'curl --fail-with-body --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}"
         --upload-file ${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz
         ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${TERRAFORM_MODULE_NAME}/${TERRAFORM_MODULE_SYSTEM}/${TERRAFORM_MODULE_VERSION}/file'
  rules:
    - if: $CI_COMMIT_TAG
```

To trigger this upload job, add a Git tag to your commit. Ensure the tag follows the [Semantic Versioning Specification](https://semver.org/) that Terraform requires. The `rules:if: $CI_COMMIT_TAG` ensures that only tagged commits to your repository trigger the module upload job.
For other ways to control jobs in your CI/CD pipeline, refer to the [`.gitlab-ci.yml`](../../../ci/yaml/index.md) keyword reference.

## Example projects

For examples of the Terraform module registry, check the projects below:

- The [_GitLab local file_ project](https://gitlab.com/mattkasa/gitlab-local-file) creates a minimal Terraform module and uploads it into the Terraform module registry using GitLab CI/CD.
- The [_Terraform module test_ project](https://gitlab.com/mattkasa/terraform-module-test) uses the module from the previous example.

## Troubleshooting

- Publishing a module with a duplicate name results in a `{"message":"Access Denied"}` error. There's an ongoing discussion about allowing duplicate module names [in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/368040).
