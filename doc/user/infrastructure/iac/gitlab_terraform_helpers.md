---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Terraform helpers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

WARNING:
The Terraform CI/CD templates are deprecated and will be removed in GitLab 18.0.
See [the deprecation announcement](../../../update/deprecations.md#deprecate-terraform-cicd-templates) for more information.

GitLab provides two helpers to ease your integration with the [GitLab-managed Terraform State](terraform_state.md).

- The `gitlab-terraform` script, which is a thin wrapper around the `terraform` command.
- The `terraform-images` container images, which include the `gitlab-terraform` script and `terraform` itself.

Both helpers are maintained in the [Terraform Images](https://gitlab.com/gitlab-org/terraform-images)
project.

## `gitlab-terraform`

The `gitlab-terraform` script is a thin wrapper around the `terraform` command.

Run `gitlab-terraform` in a CI/CD pipeline to set up the necessary environment
variables to connect to the [GitLab-managed Terraform State](terraform_state.md) backend.

### Source (but do not run) the helper script

When the `gitlab-terraform` script is sourced, it
configures the environment for a `terraform` call, but does not
actually run `terraform`. You can source the script when you need to do
extra steps to prepare your environment, or to use alternative
tools like `terragrunt`.

To source the script, execute:

```shell
source $(which gitlab-terraform)
```

Some shells, like BusyBox, do not support the case
of another script sourcing your script. For more information, see [this Stack Overflow thread](https://stackoverflow.com/a/28776166).
To resolve this issue, you should use `bash`, `zsh` or `ksh`, or source `gitlab-terraform` directly
from the shell.

### Commands

You can run `gitlab-terraform` with the following commands.

| Command                      | Forwards command line? | Implicit init?        | Description                                                                                            |
|------------------------------|------------------------|-----------------------|--------------------------------------------------------------------------------------------------------|
| `gitlab-terraform apply`     | Yes                    | Yes                   | Runs `terraform apply`.                                                                                |
| `gitlab-terraform destroy`   | Yes                    | Yes                   | Runs `terraform destroy`.                                                                              |
| `gitlab-terraform fmt`       | Yes                    | No                    | Runs `terraform fmt` in check mode.                                                                    |
| `gitlab-terraform init`      | Yes                    | Not applicable        | Runs `terraform init`.                                                                                 |
| `gitlab-terraform plan`      | Yes                    | Yes                   | Runs `terraform plan` and produces a `plan.cache` file.                                                |
| `gitlab-terraform plan-json` | No                     | No                    | Converts a `plan.cache` file into a GitLab Terraform report for a [MR integration](mr_integration.md). |
| `gitlab-terraform validate`  | Yes                    | Yes (without backend) | Runs `terraform validate`.                                                                             |
| `gitlab-terraform -- <cmd>`  | Yes                    | No                    | Runs `terraform <cmd>`, even if it is wrapped.                                                         |
| `gitlab-terraform <cmd>`     | Yes                    | No                    | Runs `terraform <cmd>`, if the command is not wrapped.                                                 |

### Generic variables

When you run `gitlab-terraform`, these variables are configured.

| Variable             | Default                                    | Description                                                                                                                                                                |
|----------------------|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `TF_ROOT`            | Not set                                    | Root of the Terraform configuration. If set, it is used as the Terraform `-chdir` argument value. All read and written files are relative to the given configuration root. |
| `TF_CLI_CONFIG_FILE` | `$HOME/.terraformrc`                       | Location of the [Terraform configuration file](https://developer.hashicorp.com/terraform/cli/config/config-file).                                                          |
| `TF_IN_AUTOMATION`   | `true`                                     | Set to `true` to indicate that Terraform commands are automated.                                                                                                           |
| `TF_GITLAB_SOURCED`  | `false`                                    | Set to `true` if `gitlab-terraform` [was sourced](#source-but-do-not-run-the-helper-script).                                                                               |
| `TF_PLAN_CACHE`      | `$TF_ROOT/plan.cache` or `$PWD/plan.cache` | Location of the plan cache file. If `TF_ROOT` is not set, then its path is relative to the current working directory (`$PWD`).                                             |
| `TF_PLAN_JSON`       | `$TF_ROOT/plan.json` or `$PWD/plan.json`   | Location of the plan JSON file for [MR integration](mr_integration.md). If `TF_ROOT` is not set, then its path is relative to the current working directory (`$PWD`).      |
| `DEBUG_OUTPUT`       | `"false"`                                  | If set to `"true"` every statement is logged with `set -x`.                                                                                                                |

### GitLab-managed Terraform state variables

When you run `gitlab-terraform`, these variables are configured.

| Variable                 | Default                                                                                                                 | Description                                                                                                                                                                                                               |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `TF_STATE_NAME`          | Not set                                                                                                                 | If `TF_ADDRESS` is not set, and `TF_STATE_NAME` is provided, then the value of `TF_STATE_NAME` is used as [GitLab-managed Terraform State](terraform_state.md) name.                                                      |
| `TF_ADDRESS`             | Terraform State API URL for `$TF_STATE_NAME`                                                                            | Used as default for [`TF_HTTP_ADDRESS`](https://developer.hashicorp.com/terraform/language/settings/backends/http#address). Uses `TF_STATE_NAME` as [GitLab-managed Terraform State](terraform_state.md) name by default. |
| `TF_USERNAME`            | [`$GITLAB_USER_LOGIN`](../../../ci/variables/predefined_variables.md) or `gitlab-ci-token` if `$TF_PASSWORD` is not set | Used as default for [`TF_HTTP_USERNAME`](https://developer.hashicorp.com/terraform/language/settings/backends/http#username).                                                                                             |
| `TF_PASSWORD`            | [`$CI_JOB_TOKEN`](../../../ci/variables/predefined_variables.md)                                                        | Used as default for [`TF_HTTP_PASSWORD`](https://developer.hashicorp.com/terraform/language/settings/backends/http#password).                                                                                             |
| `TF_HTTP_ADDRESS`        | `$TF_ADDRESS`                                                                                                           | [Address to the Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/http#address).                                                                                                    |
| `TF_HTTP_LOCK_ADDRESS`   | `$TF_ADDRESS/lock`                                                                                                      | [Address to the Terraform backend lock endpoint](https://developer.hashicorp.com/terraform/language/settings/backends/http#lock_address).                                                                                 |
| `TF_HTTP_LOCK_METHOD`    | `POST`                                                                                                                  | [Method to use for the Terraform backend lock endpoint](https://developer.hashicorp.com/terraform/language/settings/backends/http#lock_method).                                                                           |
| `TF_HTTP_UNLOCK_ADDRESS` | `$TF_ADDRESS/lock`                                                                                                      | [Address to the Terraform backend unlock endpoint](https://developer.hashicorp.com/terraform/language/settings/backends/http#unlock_address).                                                                             |
| `TF_HTTP_UNLOCK_METHOD`  | `DELETE`                                                                                                                | [Method to use for the Terraform backend unlock endpoint](https://developer.hashicorp.com/terraform/language/settings/backends/http#unlock_method).                                                                       |
| `TF_HTTP_USERNAME`       | `$TF_USERNAME`                                                                                                          | [Username to authenticate with the Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/http#username).                                                                                |
| `TF_HTTP_PASSWORD`       | `$TF_PASSWORD`                                                                                                          | [Password to authenticate with the Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/http#password).                                                                                |
| `TF_HTTP_RETRY_WAIT_MIN` | `5`                                                                                                                     | [Minimum time in seconds to wait](https://developer.hashicorp.com/terraform/language/settings/backends/http#retry_wait_min) between HTTP request attempts to the Terraform backend.                                       |

### Command variables

When you run `gitlab-terraform`, these variables are configured.

| Variable                 | Default  | Description                                                                               |
|--------------------------|----------|-------------------------------------------------------------------------------------------|
| `TF_IMPLICIT_INIT`       | `true`   | If `true`, an implicit `terraform init` runs before the wrapped commands that require it. |
| `TF_INIT_NO_RECONFIGURE` | `false`  | If `true`, the implicit `terraform init` runs without `-reconfigure`.                     |
| `TF_INIT_FLAGS`          | Not set  | Additional `terraform init` flags.                                                        |

### Terraform input variables

When you run `gitlab-terraform`, these Terraform input variables are set automatically.
For more information about the default values, see [Predefined variables](../../../ci/variables/predefined_variables.md).

| Variable                      | Default                 |
|-------------------------------|-------------------------|
| `TF_VAR_CI_JOB_ID`            | `$CI_JOB_ID`            |
| `TF_VAR_CI_COMMIT_SHA`        | `$CI_COMMIT_SHA`        |
| `TF_VAR_CI_JOB_STAGE`         | `$CI_JOB_STAGE`         |
| `TF_VAR_CI_PROJECT_ID`        | `$CI_PROJECT_ID`        |
| `TF_VAR_CI_PROJECT_NAME`      | `$CI_PROJECT_NAME`      |
| `TF_VAR_CI_PROJECT_NAMESPACE` | `$CI_PROJECT_NAMESPACE` |
| `TF_VAR_CI_PROJECT_PATH`      | `$CI_PROJECT_PATH`      |
| `TF_VAR_CI_PROJECT_URL`       | `$CI_PROJECT_URL`       |

## Terraform images

The `gitlab-terraform` helper script and `terraform` itself are provided in container images
under `registry.gitlab.com/gitlab-org/terraform-images/`. You can use these images to configure
and manage your integration.

The following images are provided:

| Image name                    | Tag                         | Description                                                                    |
|-------------------------------|-----------------------------|--------------------------------------------------------------------------------|
| `stable`                      | `latest`                    | Latest `terraform-images` release bundled with the latest Terraform release.   |
| `releases/$TERRAFORM_VERSION` | `latest`                    | Latest `terraform-images` release bundled with a specific Terraform release.   |
| `releases/$TERRAFORM_VERSION` | `$TERRAFORM_IMAGES_VERSION` | Specific `terraform-images` release bundled with a specific Terraform release. |

For supported combinations, see [the `terraform-images` container registry](https://gitlab.com/gitlab-org/terraform-images/container_registry).

## Related topics

- [Terraform CI/CD templates](_index.md)
- [Terraform template recipes](terraform_template_recipes.md)
