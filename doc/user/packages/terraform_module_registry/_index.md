---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraform Module Registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Infrastructure registry and Terraform Module Registry [merged](https://gitlab.com/gitlab-org/gitlab/-/issues/404075) into a single Terraform Module Registry feature in GitLab 15.11.
- Support for groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140215) in GitLab 16.9.

{{< /history >}}

With the Terraform Module Registry, you can:

- Use GitLab projects as a
private registry for Terraform modules.
- Create and publish
modules with GitLab CI/CD, which can then be consumed from other private
projects.

## Authenticate to the Terraform Module Registry

To authenticate to the Terraform Module Registry, you need either:

- A [personal access token](../../../api/rest/authentication.md#personalprojectgroup-access-tokens) with at least the `read_api` scope.
- A [CI/CD job token](../../../ci/jobs/ci_job_token.md).
- A [deploy token](../../project/deploy_tokens/_index.md) with the `read_package_registry` or `write_package_registry` scope, or both.

When using the API:

- If you authenticate with a deploy token, you must apply the `write_package_registry` scope to publish a module. To download a module, apply the `read_package_registry` scope.
- If you authenticate with a personal access token, you must configure it with at least the `read_api` scope.

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

## Prerequisites

To publish a Terraform module:

- You must have at least the Developer role.

To delete a module:

- You must have at least the Maintainer role.

## Publish a Terraform module

Publishing a Terraform module creates it if it does not exist.

After you publish a Terraform module, you can [view it in the **Terraform Module Registry**](#view-terraform-modules) page.

### With the API

Publish Terraform modules by using the [Terraform Module Registry API](../../../api/packages/terraform-modules.md).

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| Attribute          | Type            | Required | Description                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/rest/_index.md#namespaced-paths).                                    |
| `module-name`      | string          | yes      | The module name. Supported syntax: 1 to 64 ASCII characters, including lowercase letters (a-z) and digits (0-9). |
| `module-system`    | string          | yes      | The module system. Supported syntax: 1 to 64 ASCII characters, including lowercase letters (a-z) and digits (0-9). For more information, see [Module Registry Protocol](https://opentofu.org/docs/internals/module-registry-protocol/). |
| `module-version`   | string          | yes      | The module version. Should follow the [semantic versioning specification](https://semver.org/). |

Provide the file content in the request body.

Requests must end with `/file`.
If you send a request ending with something else, it results in a `404 Not Found` error.

{{< tabs >}}

{{< tab title="Personal access token" >}}

Example request using a personal access token:

```shell
curl --fail-with-body --header "PRIVATE-TOKEN: <your_access_token>" \
     --upload-file path/to/file.tgz \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/<your_module>/<your_system>/0.0.1/file"
```

{{< /tab >}}

{{< tab title="Deploy token" >}}

Example request using a deploy token:

```shell
curl --fail-with-body --header "DEPLOY-TOKEN: <deploy_token>" \
     --upload-file path/to/file.tgz \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/<your_module>/<your_system>/0.0.1/file"
```

{{< /tab >}}

{{< /tabs >}}

Example response:

```json
{
  "message":"201 Created"
}
```

### With a CI/CD template (recommended)

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110493) in GitLab 15.9.

{{< /history >}}

You can use the [`Terraform-Module.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform-Module.gitlab-ci.yml)
or the advanced [`Terraform/Module-Base.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Module-Base.gitlab-ci.yml)
CI/CD template to publish a Terraform module to the GitLab Terraform Module Registry:

```yaml
include:
  template: Terraform-Module.gitlab-ci.yml
```

The pipeline contains the following jobs:

- `fmt`: Validates the formatting of the Terraform module
- `kics-iac-sast`: Tests the Terraform module for security issues
- `deploy`: Deploys the Terraform module to the Terraform Module Registry (for tag pipelines only)

#### Use pipeline variables

Configure the pipeline with the following variables:

| Variable                   | Default              | Description                                                                                     |
|----------------------------|----------------------|-------------------------------------------------------------------------------------------------|
| `TERRAFORM_MODULE_DIR`     | `${CI_PROJECT_DIR}`  | The relative path to the root directory of the Terraform project.                               |
| `TERRAFORM_MODULE_NAME`    | `${CI_PROJECT_NAME}` | The module name. Must not contain any spaces or underscores.                  |
| `TERRAFORM_MODULE_SYSTEM`  | `local`              | The system or provider of your module targets. For example, `local`, `aws`, or `google`. |
| `TERRAFORM_MODULE_VERSION` | `${CI_COMMIT_TAG}`   | The module version. Should follow the [semantic versioning specification](https://semver.org/).          |

### Configure CI/CD manually

To work with Terraform modules in [GitLab CI/CD](../../../ci/_index.md), use a
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example, this job uploads a new module for the `local` [system provider](https://registry.terraform.io/browse/providers)
and uses the module version from the Git commit tag:

```yaml
stages:
  - deploy

upload:
  stage: deploy
  image: curlimages/curl:latest
  variables:
    TERRAFORM_MODULE_DIR: ${CI_PROJECT_DIR}    # The relative path to the root directory of the Terraform project.
    TERRAFORM_MODULE_NAME: ${CI_PROJECT_NAME}  # The name of your Terraform module, must not have any spaces or underscores (will be translated to hyphens).
    TERRAFORM_MODULE_SYSTEM: local             # The system or provider your Terraform module targets (ex. local, aws, google).
    TERRAFORM_MODULE_VERSION: ${CI_COMMIT_TAG} # The version - it's recommended to follow SemVer for Terraform Module Versioning.
  script:
    - TERRAFORM_MODULE_NAME=$(echo "${TERRAFORM_MODULE_NAME}" | tr " _" -) # module-name must not have spaces or underscores, so translate them to hyphens
    - tar -vczf /tmp/${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz -C ${TERRAFORM_MODULE_DIR} --exclude=./.git .
    - 'curl --fail-with-body --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}"
         --upload-file /tmp/${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz
         ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${TERRAFORM_MODULE_NAME}/${TERRAFORM_MODULE_SYSTEM}/${TERRAFORM_MODULE_VERSION}/file'
  rules:
    - if: $CI_COMMIT_TAG
```

To trigger this upload job, add a Git tag to your commit.
Ensure the tag follows the required [semantic versioning specification](https://semver.org/) for Terraform.
The `rules:if: $CI_COMMIT_TAG` ensures
that only tagged commits to your repository trigger the module upload job.

For other ways to control jobs in your CI/CD pipeline, see the [CI/CD YAML syntax reference](../../../ci/yaml/_index.md).

### Module resolution workflow

When you upload a new module, GitLab generates a path for the module. For example:

- `https://gitlab.example.com/parent-group/my-infra-package`

This path conforms with [the Terraform Module Registry Protocol](https://opentofu.org/docs/internals/module-registry-protocol/), where:

- `gitlab.example.com` is the hostname.
- `parent-group` is the unique, top-level [namespace](../../namespace/_index.md) of the Terraform Module Registry.
- `my-infra-package` is the name of the module.

If [duplicates are not allowed](#allow-duplicate-terraform-modules), the module name and version must be unique in all groups, subgroups, and projects under `parent-group`. Otherwise, you receive the following error:

- `{"message":"A module with the same name already exists in the namespace."}`

If [duplicates are allowed](#allow-duplicate-terraform-modules), module resolution is based on the most recently published module.

For example, if:

- The project is `gitlab.example.com/parent-group/subgroup/my-project`.
- The Terraform module is `my-infra-package`.
If duplicates are allowed, `my-infra-package` is a valid module.
If duplicates are not allowed, the module name must be unique in all
projects in all groups under `parent-group`.

When you name a module, keep these naming conventions in mind:

- Your project and group names must not include a dot (`.`).
For example, `source = "gitlab.example.com/my.group/project.name"` is invalid.
- Module versions should follow the [semantic versioning specification](https://semver.org/).

### Allow duplicate Terraform modules

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368040) in GitLab 16.8.
- Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/370471) from Maintainer to Owner in GitLab 17.0.

{{< /history >}}

By default, the Terraform Module Registry enforces uniqueness for module names in the same namespace.

To allow publishing duplicate module names:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **Packages and registries**.
1. In the **Terraform module** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names of modules to allow.

Your changes are automatically saved.

{{< alert type="note" >}}

If **Allow duplicates** is turned on, you can specify module names that should not have duplicates in the **Exceptions** text box.

{{< /alert >}}

You can also allow publishing duplicate names by enabling `terraform_module_duplicates_allowed` in the [GraphQL API](../../../api/graphql/reference/_index.md#packagesettings).

To allow duplicates with specific names:

1. Ensure `terraform_module_duplicates_allowed` is disabled.
1. Use `terraform_module_duplicate_exception_regex` to define a regex pattern for the module names you want to allow duplicates for.

The top-level namespace setting takes precedence over the child namespace settings.
For example, if you enable `terraform_module_duplicates_allowed` for a group, and disable it for a subgroup,
duplicates are allowed for all projects in the group and its subgroups.

For more information on module resolution, see [module resolution workflow](#module-resolution-workflow)

## View Terraform modules

{{< history >}}

- Support for `README` files [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438060) in GitLab 17.2.

{{< /history >}}

To view Terraform modules in your project or group:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Operate** > **Terraform modules**.

You can search, sort, and filter modules on this page.

To view a module's `README` file:

1. From the **Terraform Module Registry** page, select a Terraform module.
1. Select **`README`**.

## Reference a Terraform module

Reference a module from a group or project.

### From a namespace

You can provide authentication tokens (job tokens, personal access tokens, or deploy tokens) for `terraform` in environment variables.

You should add the prefix `TF_TOKEN_` to the domain name of environment variables, with periods encoded as underscores.
For more information, see [Environment Variable Credentials](https://opentofu.org/docs/cli/config/config-file/#environment-variable-credentials).

For example, the value of a variable named `TF_TOKEN_gitlab_com` is used as a deploy token when the CLI makes service requests to the hostname `gitlab.com`:

```shell
export TF_TOKEN_gitlab_com='glpat-<deploy_token>'
```

This method is preferred for enterprise implementations. For local or temporary environments,
you might want to create a `~/.terraformrc` or `%APPDATA%/terraform.rc` file:

```terraform
credentials "<gitlab.com>" {
  token = "<TOKEN>"
}
```

Where `gitlab.com` can be replaced with the hostname of
your GitLab Self-Managed instance.

You can then refer to your Terraform module from a downstream Terraform project:

```terraform
module "<module>" {
  source = "gitlab.com/<namespace>/<module-name>/<module-system>"
}
```

### From a project

To reference a Terraform module using a project source,
use the [fetching archives over HTTP](https://developer.hashicorp.com/terraform/language/modules/sources#fetching-archives-over-http) source type provided by Terraform.

You can provide authentication tokens (job tokens, personal access tokens, or deploy tokens) for `terraform` in your `~/.netrc` file:

```plaintext
machine <gitlab.com>
login <USERNAME>
password <TOKEN>
```

Where `gitlab.com` can be replaced with the hostname of your GitLab Self-Managed instance,
and `<USERNAME>` is your token username.

You can refer to your Terraform module from a downstream Terraform project:

```terraform
module "<module>" {
  source = "https://gitlab.com/api/v4/projects/<project-id>/packages/terraform/modules/<module-name>/<module-system>/<module-version>"
}
```

If you need to reference the latest version of a module, you can omit the `<module-version>` from the source URL. To prevent future issues, you should reference a specific version if possible.

If there are [duplicate module names](#allow-duplicate-terraform-modules) in the same namespace, referencing the module from the namespace level installs the recently published module. To reference a specific version of a duplicate module, use the [project-level](#from-a-project) source type.

## Download a Terraform module

To download a Terraform module:

1. On the left sidebar, select **Operate** > **Terraform modules**.
1. Select the name of the module you want to download.
1. From the **Assets** table, select the module you want to download.

## Delete a Terraform module

You cannot edit a Terraform module after you publish it in the Terraform Module Registry. Instead, you
must delete and recreate it.

You can delete modules by using [the packages API](../../../api/packages.md#delete-a-project-package) or the UI.

To delete a module in the UI, from your project:

1. On the left sidebar, select **Operate** > **Terraform modules**.
1. Find the name of the package you want to delete.
1. Select **Delete**.

The package is permanently deleted.

## Disable the Terraform Module Registry

The Terraform Module Registry is automatically enabled.

For GitLab Self-Managed instances, a GitLab administrator can
[disable](../../../administration/packages/_index.md#enable-or-disable-the-package-registry) **Packages and registries**,
which removes this menu item from the sidebar.

You can also remove the Terraform Module Registry for a specific project:

1. In your project, go to **Settings** > **General**.
1. Expand the **Visibility, project features, permissions** section and toggle **Packages** off.
1. Select **Save changes**.

## Example projects

For examples of the Terraform Module Registry, check the projects below:

- The [_GitLab local file_ project](https://gitlab.com/mattkasa/gitlab-local-file) creates a minimal Terraform module and uploads it into the Terraform Module Registry using GitLab CI/CD.
- The [_Terraform module test_ project](https://gitlab.com/mattkasa/terraform-module-test) uses the module from the previous example.
