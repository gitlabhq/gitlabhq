---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager
ignore_in_report: true
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16319) in GitLab 18.3 [with the flags](../../../development/feature_flags/_index.md) `secrets_manager` and `ci_tanukey_ui`. Disabled by default.
- Feature flag `ci_tanukey_ui` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/549940) in GitLab 18.4.
- Made available to some users in a closed beta in GitLab 18.8.
- Group secrets manager [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17904) and made available to closed beta users in 18.10 [with the flag](../../../development/feature_flags/_index.md) `group_secrets_manager`.

{{< /history >}}

> [!warning]
> This feature is an [experiment](../../../policy/development_stages_support.md#experiment) and subject to change without
> notice. Secrets stored in experiment or beta versions will not be kept when the Secrets Manager is released as generally available.
> This feature is not ready for public testing or production use.

Secrets represent sensitive information your CI/CD jobs need to function. Secrets could be access tokens,
database credentials, private keys, or similar.

Unlike CI/CD variables, which are always available to jobs by default, secrets must be explicitly requested by a job.

Use the GitLab Secrets Manager to securely store and manage secrets and credentials for your projects and groups.

## Enable or disable the GitLab Secrets Manager

### For a project

Prerequisites:

- You must have the Owner role for the project.

To enable or disable GitLab Secrets Manager for a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets manager** toggle and wait for the secrets manager to be provisioned.

   > [!warning]
   > If you later disable the Secrets Manager for the project, all the project secrets are permanently deleted.
   > These secrets cannot be recovered.

Secrets defined for a project can only be accessed by pipelines from the same project.

### For a group

Prerequisites:

- You must have the Owner role for the group.

To enable or disable GitLab Secrets Manager for a group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Turn on the **Secrets manager** toggle and wait for the secrets manager to be provisioned.

   > [!warning]
   > If you later disable the Secrets Manager for the group, all the group secrets are permanently deleted.
   > These secrets cannot be recovered.

Secrets defined for a group can only be accessed by pipelines in a project directly under the group or in its subgroup hierarchy.

## Define a secret

You can add secrets to the secrets manager so that it can be used for secure CI/CD pipelines
and workflows.

1. In the top bar, select **Search or go to** and find your project
1. Select **Secure** > **Secrets manager**.
1. Select **Add secret** and fill in the details:
   - **Name**: Must be unique in the project.
   - **Value**: Must be 10 KB (10,000 bytes) or less.
   - **Description**: Maximum of 200 characters.
   - **Environments**: Can be:
     - **All (default)** (`*`)
     - A specific [environment](../../environments/_index.md#types-of-environments).
     - A [wildcard environment](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Branch**: Option only exists in project settings. Can be:
     - A specific branch.
     - A wildcard branch (must have the `*` character).
   - **Protected**: Option only exists in group settings. Optional. Export secrets to pipelines running on protected branches only.
   - **Rotation reminder**: Optional. Send an email reminder to rotate the secret after the set number of days.
     Minimum 7 days.

After you create a secret, you can use it in the pipeline configuration or in job scripts.

> [!warning]
> The value of a secret is accessible to all CI/CD pipeline jobs running for the specific environment or branch
> defined when the secret is created or updated. Ensure only users with permission to access
> the value of these secrets can run jobs for the specified environment or branch.

## Use secrets in job scripts

### For project secrets

Prerequisites:

- GitLab Runner 18.6 or later.

To access secrets defined with the Secret Manager, use the [`secrets`](../../yaml/_index.md#secrets)
and `gitlab_secrets_manager` keywords.

Similar to [file type variables](../../variables/_index.md#use-file-type-cicd-variables),
the secret is made available as an environment variable with:

- The secret's key as the environment variable name.
- The secret's value saved to a temporary file. Unlike masked variables, secrets can have spaces and newlines.
- The path to the temporary file as the environment variable value.

For example:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube-cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

If a job outputs a secret's value, for example by running `cat $KUBE_CA_PEM`,
GitLab replaces the value in the job log with `[MASKED]`.

### For group secrets

Prerequisites:

- GitLab Runner 18.10 or later.

To access group secrets:

- Use the [`secrets`](../../yaml/_index.md#secrets) and `gitlab_secrets_manager` keywords.
- Specify the secret manager source with the `source` field with the format `group/<full-path-to-group>`.

For example:

```yaml
job:
  secrets:
    TEST_SECRET:
      gitlab_secrets_manager:
        name: foo
        source: group/<full-path-to-group>
  script:
   - cat $TEST_SECRET
```

## Manage secrets permissions

### For a project

Prerequisites:

- You must have the Owner role for the project to manage the secrets permissions.
- Users with the Maintainer role for the project can view the defined permissions.
- The Secrets Manager must be enabled for the project.

To update the secrets permissions for a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Secrets manager**, in the **Secrets manager user permissions** section, you can manage the user permissions:
   - Select **Add** to add permissions rules for specific users, groups, or roles.
   - You can set permission scopes to read, write (create & update), and delete secrets.

### For a group

Prerequisites:

- You must have the Owner role for the group to be able to manage the secrets permissions.
  Only users with the Owner role for the group can view the defined permissions.
- The Secrets Manager must be enabled for the group.

To update the secrets permissions for a group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Secrets manager**, in the **Secrets manager user permissions** section, you can manage the user permissions:
   - Select **Add** to add permissions rules for specific users, groups, or roles.
   - You can set permission scopes to read, write (create & update), and delete secrets.

Users with the Owner role for the group always have permissions to perform all operations in the Secrets Manager.

## Deletion of a project or group

When you [delete a project](../../../user/project/working_with_projects.md#delete-a-project) or [delete a group](../../../user/group/_index.md#schedule-a-group-for-deletion) with secrets:

- The secrets manager for the project or group is disabled and removed from the secrets storage engine.
- All the secrets are permanently deleted.

## Transfer of a project or group

When you [transfer a project](../../../user/project/working_with_projects.md#transfer-a-project) or [transfer a group](../../../user/group/manage.md#transfer-a-group) with secrets:

- The secrets defined for the project or group are not transferred to the project or group in its new namespace.
- The secrets manager for the project or group is disabled and removed from the secrets storage engine.
- All the secrets are permanently deleted.

## Secret rotation notifications

Users with the Owner role in the project receive an email notification to rotate a secret on the day specified in a secret's configuration.

## Troubleshooting

### Error: `reading from Vault: api error: status code 403`

When a CI/CD pipeline job attempts to fetch a secret, it might return this error:

```plaintext
ERROR: Job failed (system failure): resolving secrets: getting secret: get secret data: reading from Vault: api error: status code 403: 1 error occurred: * permission denied
```

This error happens when a job attempts to fetch a secret that does not exist or has been deleted.

### Error: `inline auth JWT is required`

When a CI/CD pipeline job attempts to fetch a secret, it might return this error:

```plaintext
ERROR: Job failed (system failure): resolving secrets: creating vault client: configuring inline auth: inline auth JWT is required
```

This error happens when the secrets manager instance has not been provisioned yet for the project or the group
that the secret is expected to belong to. The runner cannot configure authentication because no secrets
manager role exists yet.

To resolve this error, [enable the Secrets Manager](#enable-or-disable-the-gitlab-secrets-manager)
for your project or group.

Wait for provisioning to complete and create the secret before re-running the pipeline.
