---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-managed Terraform/OpenTofu state
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Support for state names that contain periods introduced in GitLab 15.7 [with a flag](../../../administration/feature_flags/_index.md) named `allow_dots_on_tf_state_names`. Disabled by default.
- Support for state names that contain periods [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/385597) in GitLab 16.0. Feature flag `allow_dots_on_tf_state_names` removed.
- Support for GitLab-managed OpenTofu and Terraform states [introduced](https://gitlab.com/gitlab-org/cli/-/issues/7954) in GitLab 18.3. Requires GitLab CLI (`glab`) 1.66 or later.

{{< /history >}}

Managing infrastructure state files across teams requires both security and reliability. GitLab-managed
OpenTofu state eliminates the typical challenges of state management.
With minimal configuration, your OpenTofu states become a natural extension of your GitLab project.
This integration keeps your infrastructure definitions, code, and state all in one secure location.

With GitLab-managed OpenTofu state, you:

- Store state files securely with automatic encryption at rest
- Track changes with built-in versioning to identify who changed what and when
- Control access using the GitLab permission model rather than creating separate authentication systems
- Collaborate across teams without state file conflicts or corruption
- Integrate seamlessly with your existing GitLab CI/CD pipelines
- Access state remotely from both CI/CD jobs and local development environments

{{< alert type="warning" >}}

**Disaster recovery planning**
OpenTofu state files are encrypted with the Lockbox Ruby gem when they are at rest on disk and in object storage with a key derived from the `db_key_base` application setting.
[To decrypt a state file, GitLab must be available](https://gitlab.com/gitlab-org/gitlab/-/issues/335739).
If it is offline, and you use GitLab to deploy infrastructure that GitLab requires (like virtual machines,
Kubernetes clusters, or network components), you cannot access the state file easily or decrypt it.
Additionally, if GitLab serves up OpenTofu modules or other dependencies that are required to bootstrap GitLab,
these will be inaccessible. To work around this issue, make other arrangements to host or back up these dependencies,
or consider using a separate GitLab instance with no shared points of failure.

{{< /alert >}}

## Prerequisites

For GitLab Self-Managed, before you can use GitLab for your OpenTofu state files:

- An administrator must [set up Terraform/OpenTofu state storage](../../../administration/terraform_state.md).
- You must turn on the **Infrastructure** menu for your project:
  1. Go to **Settings** > **General**.
  1. Expand **Visibility, project features, permissions**.
  1. Under **Infrastructure**, turn on the toggle.

## Initialize an OpenTofu state as a backend by using GitLab CI/CD

Prerequisites:

- To lock, unlock, and write to the state by using `tofu apply`, you must have at least the Maintainer role.
- To read the state by using `tofu plan -lock=false`, you must have at least the Developer role.

{{< alert type="warning" >}}

Like any other job artifact, OpenTofu plan data is viewable by anyone with the Guest role on the repository.
Neither OpenTofu nor GitLab encrypts the plan file by default. If your OpenTofu `plan.json` or `plan.cache`
files include sensitive data like passwords, access tokens, or certificates, you should
encrypt the plan output or modify the project visibility settings. You should also **disable**
[public pipelines](../../../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects)
and set the [artifact's access flag to 'developer'](../../../ci/yaml/_index.md#artifactsaccess) (`access: 'developer'`).
This setting ensures artifacts are accessible only to GitLab administrators and project members with at least the Developer role.

{{< /alert >}}

To configure GitLab CI/CD as a backend:

1. In your OpenTofu project, in a `.tf` file like `backend.tf`,
   define the [HTTP backend](https://opentofu.org/docs/language/settings/backends/http/):

   ```hcl
   terraform {
     backend "http" {
     }
   }
   ```

1. In the root directory of your project repository, create a `.gitlab-ci.yml` file. Use the
   [OpenTofu CI/CD component](https://gitlab.com/components/opentofu) to form your `.gitlab-ci.yml` file.
1. Push your project to GitLab. This action triggers a pipeline, which
   runs the `gitlab-tofu init`, `gitlab-tofu validate`, and
   `gitlab-tofu plan` commands.
1. Trigger the manual `deploy` job from the previous pipeline. This action runs the `gitlab-tofu apply` command, which provisions the defined infrastructure.

The output from the previous commands should be viewable in the job logs.

The `gitlab-tofu` CLI is a wrapper around the `tofu` CLI.

### Customizing your OpenTofu environment variables

You can use [OpenTofu HTTP configuration variables](https://opentofu.org/docs/language/settings/backends/http/#configuration-variables) when you define your CI/CD jobs.

To customize your `init` and override the OpenTofu configuration,
use environment variables instead of the `init -backend-config=...` approach.
When you use `-backend-config`, the configuration is:

- Cached in the output of the `plan` command.
- Usually passed forward to the `apply` command.

This configuration can lead to problems like [being unable to lock the state files in CI jobs](troubleshooting.md#cant-lock-terraform-state-files-in-ci-jobs-for-terraform-apply-with-a-previous-jobs-plan).

#### Customize the plan filename

By default, the `gitlab-tofu plan` (or `gitlab-terraform plan`) command always writes the plan output to a file named `plan.cache`.

To change the filename, set the `TF_PLAN_CACHE` environment variable in your CI/CD pipeline configuration. For example, to
set the filename to `my-plan.tfplan`:

```yaml
variables:
  TF_PLAN_CACHE: "my-plan.tfplan"
```

{{< alert type="note" >}}

Do not set the output filename by passing the `-out=<filename>` option. GitLab commands override this option.

{{< /alert >}}

## Access the state from your local machine

You can access the GitLab-managed OpenTofu state from your local machine.

{{< alert type="warning" >}}

On clustered deployments of GitLab, you should not use local storage.
A split state can occur across nodes, making subsequent OpenTofu executions
inconsistent. Instead, use a remote storage resource.

{{< /alert >}}

1. Ensure the OpenTofu state has been
   [initialized for CI/CD](#initialize-an-opentofu-state-as-a-backend-by-using-gitlab-cicd).
1. Copy a pre-populated OpenTofu `init` command:

   1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   1. Select **Operate** > **Terraform states**.
   1. Next to the environment you want to use, select **Actions**
      ({{< icon name="ellipsis_v" >}}) and select **Copy Terraform init command**.

1. Open a terminal and run this command on your local machine.

## Migrate to a GitLab-managed OpenTofu state

OpenTofu supports copying the state when the backend changes or is
reconfigured. Use these actions to migrate from another backend to
GitLab-managed OpenTofu state.

You should use a local terminal to run the commands needed for migrating to GitLab-managed OpenTofu state.

The following example demonstrates how to change the state name. The same workflow is needed to migrate to GitLab-managed OpenTofu state from a different state storage backend.

You should run these commands [on your local machine](#access-the-state-from-your-local-machine).

### Set up the initial backend

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

To initialize a backend with `glab`, run the following command:

```shell
glab opentofu init <old_state_name>
```

{{< /tab >}}

{{< tab title="Manually with OpenTofu CLI" >}}

To initialize a backend with OpenTofu CLI, run the following command:

```shell
PROJECT_ID="<gitlab-project-id>"
TF_USERNAME="<gitlab-username>"
TF_PASSWORD="<gitlab-personal-access-token>"
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/old-state-name"

tofu init \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5
```

{{< /tab >}}

{{< /tabs >}}

If the backend is initialized successfully,
you receive the following response:

```plaintext
Initializing the backend...

Successfully configured the backend "http"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
re-run this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### Change the backend

Now that `tofu init` has created a `.terraform/` directory that knows where
the old state is, you can tell it about the new location:

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
glab opentofu init <new-state-name> -- -migrate-state
```

{{< /tab >}}

{{< tab title="Manually with OpenTofu CLI" >}}

```shell
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/<new-state-name>"

tofu init \
  -migrate-state \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5
```

{{< /tab >}}

{{< /tabs >}}

If the backend is initialized successfully,
you receive the following response. If you type `yes`, it copies your state from the old location to the new
location. You can then go back to running it in GitLab CI/CD:

```plaintext
Initializing the backend...
Backend configuration changed!

Terraform has detected that the configuration specified for the backend
has changed. Terraform will now check for existing state in the backends.


Acquiring state lock. This may take a few moments...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "http" backend to the
  newly configured "http" backend. No existing state was found in the newly
  configured "http" backend. Do you want to copy this state to the new "http"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "http"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Use your GitLab backend as a remote data source

You can use a GitLab-managed OpenTofu state backend as an
[OpenTofu data source](https://opentofu.org/docs/language/state/remote-state-data/).

1. In your `main.tf` or other relevant file, declare these variables. Leave the values empty.

   ```hcl
   variable "example_remote_state_address" {
     type = string
     description = "Gitlab remote state file address"
   }

   variable "example_username" {
     type = string
     description = "Gitlab username to query remote state"
   }

   variable "example_access_token" {
     type = string
     description = "GitLab access token to query remote state"
   }
   ```

1. To override the values from the previous step, create a file named `example.auto.tfvars`. This file should **not** be versioned in your project repository.

   ```plaintext
   example_remote_state_address = "https://gitlab.com/api/v4/projects/<TARGET-PROJECT-ID>/terraform/state/<TARGET-STATE-NAME>"
   example_username = "<GitLab username>"
   example_access_token = "<GitLab personal access token>"
   ```

1. In a `.tf` file, define the data source by using [OpenTofu input variables](https://opentofu.org/docs/language/values/variables/):

   ```hcl
   data "terraform_remote_state" "example" {
     backend = "http"

     config = {
       address = var.example_remote_state_address
       username = var.example_username
       password = var.example_access_token
     }
   }
   ```

   - **address**: The URL of the remote state backend you want to use as a data source.
     For example, `https://gitlab.com/api/v4/projects/<TARGET-PROJECT-ID>/terraform/state/<TARGET-STATE-NAME>`.
   - **username**: The username to authenticate with the data source. If you are using
     a [personal access token](../../profile/personal_access_tokens.md) for
     authentication, this value is your GitLab username. If you are using GitLab CI/CD, this value is `'gitlab-ci-token'`.
   - **password**: The password to authenticate with the data source. If you are using a personal access token for
     authentication, this value is the token value (the token must have the **API** scope).
     If you are using GitLab CI/CD, this value is the contents of the `${CI_JOB_TOKEN}` CI/CD variable.

Outputs from the data source can now be referenced in your Terraform resources
using `data.terraform_remote_state.example.outputs.<OUTPUT-NAME>`.

To read the OpenTofu state in the target project, you need at least the Developer role.

## Manage OpenTofu state files

To view OpenTofu state files:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Operate** > **Terraform states**.

[An epic exists](https://gitlab.com/groups/gitlab-org/-/epics/4563) to track improvements to this UI.

### Manage individual OpenTofu state versions

Manage individual state versions using either
the GitLab CLI (`glab`) or the API.

Prerequisites:

- To get state versions using their serial number, you must have at least the Developer role.
- To remove state versions using their serial number, you must have at least the Maintainer role.

To get state versions using their serial number:
{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
glab opentofu state download <your_state_name> <version_serial_number>
```

{{< /tab >}}

{{< tab title="Manually with curl" >}}

```shell
curl --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/versions/<version_serial_number>"
```

{{< /tab >}}

{{< /tabs >}}

To remove state versions using their serial number:

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
glab opentofu state delete <your_state_name> <version_serial_number>
```

{{< /tab >}}

{{< tab title="Manually with curl" >}}

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/versions/<version_serial_number>"
```

{{< /tab >}}

{{< /tabs >}}

### Remove a state file

Prerequisites:

- To remove a state file, you must have at least the Maintainer role.

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
glab opentofu state delete <your_state_name>
```

{{< /tab >}}

{{< tab title="Manually with curl" >}}

```shell
curl --request DELETE --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>"
```

You can also use [CI/CD job token](../../../ci/jobs/ci_job_token.md) and basic authentication:

```shell
curl --request DELETE --user "gitlab-ci-token:$CI_JOB_TOKEN" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>"
```

You can also use [the GraphQL API](../../../api/graphql/reference/_index.md#mutationterraformstatedelete).

{{< /tab >}}

{{< tab title="Using the UI" >}}

To remove a state file using the UI:

1. On the left sidebar, select **Operate** > **Terraform states**.
1. In the **Actions** column, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Remove state file and versions**.

{{< /tab >}}

{{< /tabs >}}

### Lock and unlock a state

Prerequisites:

- To lock a state file, you must have at least the Maintainer role.

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
# Lock a state file
glab opentofu state lock <your_state_name>

# Unlock a state file
glab opentofu state unlock <your_state_name>
```

{{< /tab >}}

{{< tab title="Manually with curl" >}}

```shell
# Lock a state file
curl --request POST --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/lock"

# Unlock a state file
curl --request DELETE --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/lock"
```

{{< /tab >}}

{{< tab title="Using the UI" >}}

To lock or unlock a state file using the UI:

1. On the left sidebar, select **Operate** > **Terraform states**.
1. In the **Actions** column, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Lock** to lock or **Actions** ({{< icon name="ellipsis_v" >}}) > **Unlock**.

{{< /tab >}}

{{< /tabs >}}

### Download a state file

Prerequisites:

- To download a state file, you must have at least the Developer role.

{{< tabs >}}

{{< tab title="Using the GitLab CLI (glab)" >}}

```shell
# Download the latest state
glab opentofu state download <your_state_name>

# Download a specific version (serial) of a state
glab opentofu state download <your_state_name> <your_serial>
```

{{< /tab >}}

{{< tab title="Manually with curl" >}}

```shell
# Download the latest state
curl --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>"

# Download a specific version (serial) of a state
curl --header "Private-Token: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/versions/<version_serial_number>"
```

{{< /tab >}}

{{< tab title="Using the UI" >}}

To download the latest state file using the UI:

1. On the left sidebar, select **Operate** > **Terraform states**.
1. In the **Actions** column, select **Actions** ({{< icon name="ellipsis_v" >}}) > **Download JSON**.

There is no way to download a specific version of the state using the UI.

{{< /tab >}}

{{< /tabs >}}

## Related topics

- [Troubleshooting GitLab-managed Terraform state](troubleshooting.md)
- [Sample project: Terraform deployment of AWS EC2 instance in a custom VPC](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-aws)
