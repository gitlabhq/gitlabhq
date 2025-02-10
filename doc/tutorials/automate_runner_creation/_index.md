---
stage: none
group: Tutorials
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Automate runner creation and registration'
---

This tutorial describes how to automate runner creation and registration.

To automate runner creation and registration:

1. [Create a personal access token](#create-a-personal-access-token).
1. [Create a runner configuration](#create-a-runner-configuration).
1. [Automate GitLab Runner installation and registration](#automate-runner-installation-and-registration).
1. [View runners with the same configuration](#view-runners-with-the-same-configuration).

NOTE:
The instructions in this tutorial describe runner creation and registration
with runner authentication tokens, which have replaced the deprecated registration
method that uses registration tokens. For more information, see
[The new runner registration workflow](../../ci/runners/new_creation_workflow.md#the-new-runner-registration-workflow).

## Before you begin

- GitLab Runner must be installed on your GitLab instance.
- To create instance runners, you must be an administrator.
- To create group runners, you must be an administrator or have the Owner role for the group.
- To create project runners, you must be an administrator or have the Maintainer role for the project.

## Create an access token

Create an access token so that you can use the REST API to create runners.

You can create:

- A personal access token to use with shared, group, and project runners.
- A group or project access token to use with group and project runners.

The access token is only visible once in the GitLab UI. After you leave the page,
you no longer have access to the token. You should use a secrets management solution
to store the token, like HashiCorp Vault or the Keeper Secrets Manager Terraform plugin.

### Create a personal access token

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) the maximum allowable lifetime limit to an increased value of 400 days in GitLab 17.6 [with a flag](../../administration/feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. Enter a name and expiry date for the token.
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).
1. In the **Select scopes** section, select the **create_runner** checkbox.
1. Select **Create personal access token**.

### Create a project or group access token

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) the maximum allowable lifetime limit to an increased value of 400 days in GitLab 17.6 [with a flag](../../administration/feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

WARNING:
Project access tokens are treated as [internal users](../../administration/internal_users.md).
If an internal user creates a project access token, that token is able to access
all projects that have visibility level set to [Internal](../../user/public_access.md).

To create a project access token:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Access tokens**.
1. Select **Add new token**
1. Enter a name. The token name is visible to any user with permissions to view
   the group or project.
1. Enter an expiry date for the token.
   - The token expires on that date at midnight UTC. A token with the expiration date of 2024-01-01 expires at 00:00:00 UTC on 2024-01-01.
   - If you do not enter an expiry date, the expiry date is automatically set
     to 365 days later than the current date.
   - By default, this date can be a maximum of 365 days later than the current date. In GitLab 17.6 or later, you can [extend this limit to 400 days](https://gitlab.com/gitlab-org/gitlab/-/issues/461901).

   - An instance-wide [maximum lifetime](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)
     setting can limit the maximum allowable lifetime on self-managed instances.
1. From the **Select a role** dropdown list:
   - For the project access token, select **Maintainer**.
   - For the group access token, select **Owner**.
1. In the **Select scopes** section, select the **create_runner** checkbox.
1. Select **Create project access token**.

## Create a runner configuration

A runner configuration is where you configure runners to your requirements.

After you create a runner configuration, you receive a runner authentication
to register the runner. One or many runners can be linked to the
same configuration when these runners are registered with the same runner authentication
token. The runner configuration is stored in the `config.toml` file.

To create a runner configuration, you can use:

- The GitLab REST API.
- The `gitlab_user_runner` Terraform resource.

### With the GitLab REST API

Before you begin, you need:

- The URL for your GitLab instance. For example, if your project is hosted on
  `gitlab.example.com/yourname/yourproject`, your GitLab instance URL is
  `https://gitlab.example.com`.
- For group or project runners, the ID number of the group or project. The ID number
  is displayed in the project or group overview page, under the project or group
  name.

Use the access token in the [`POST /user/runners`](../../api/users.md#create-a-runner-linked-to-a-user)
REST endpoint to create a runner:

1. Use `curl` to invoke the endpoint to create a runner:

   ::Tabs

   :::TabTitle Project

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=project_type"
     --data "project_id=<project_id>"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <project_access_token>"
   ```

   :::TabTitle Group

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=group_type"
     --data "group_id=<group_id>"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <group_access_token>"
   ```

   :::TabTitle Shared

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=instance_type"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <personal_access_token>"
   ```

   ::EndTabs

1. Save the returned `token` value in a secure location or your secrets management
   solution. The `token` value is returned only once in the API response.

### With the `gitlab_user_runner` Terraform resource

To create the runner configuration with Terraform, use the
[`gitlab_user_runner` Terraform resource](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/blob/main/docs/resources/user_runner.md?ref_type=heads)
from the [GitLab Terraform provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab).

Here's an example configuration block:

```terraform
resource "gitlab_user_runner" "example_runner" {
  runner_type = "instance_type"
  description = "my-runner"
  tag_list = ["shell", "docker"]
}
```

## Automate runner installation and registration

If you host the runner on a virtual machine instance in a public cloud, you can automate
runner installation and registration.

After you create a runner and its configuration, you can use the same runner
authentication token to register multiple runners with the same configuration.
For example, you can deploy multiple instance runners with the same executor type
and job tags to the target compute host. Each runner registered with the same runner
authentication token has a unique `system_id`, which GitLab Runner
generates randomly and stores in your local file system.

Here's an example of an automation workflow you can use to register and deploy your
runners to Google Compute Engine:

1. Use [Terraform infrastructure as code](../../user/infrastructure/iac/_index.md)
   to install the runner application to a virtual machine hosted on Google Cloud
   Platform (GCP).
1. In the [GCP Terraform provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance),
   use the `metadata` key to add the runner authentication token to the runner
   configuration file on the GCP virtual machine.
1. To register the runner with the target GitLab instance, use a `cloud-init` script
   populated from the GCP Terraform provider. Here's an example:

   ```shell
   #!/bin/bash
   apt update
   curl --location "https://packages.gitlab.com/install/repositories/runner/
   gitlab-runner/script.deb.sh" | bash
   GL_NAME=$(curl 169.254.169.254/computeMetadata/v1/instance/name
   --header "Metadata-Flavor:Google")
   GL_EXECUTOR=$(curl 169.254.169.254/computeMetadata/v1/instance/attributes/
   gl_executor --header "Metadata-Flavor:Google")
   apt update
   apt install -y gitlab-runner
   gitlab-runner register --non-interactive --name="$GL_NAME" --url="https://gitlab.com"
     --token="$RUNNER_TOKEN" --request-concurrency="12" --executor="$GL_EXECUTOR"
     --docker-image="alpine:latest"
   systemctl restart gitlab-runner
   ```

## View runners with the same configuration

Now that you've automated your runner creation and automation, you can view
the runners that use the same configuration in the GitLab UI.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. In the search box, enter the runner description or search the list of runners.
1. To view the runners that use the same configuration, in the **Details** tab,
   next to **Runners**, select **Show details**.
