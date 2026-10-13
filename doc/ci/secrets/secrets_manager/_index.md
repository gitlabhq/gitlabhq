---
stage: Security Platform
group: Secrets Manager Application
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secrets Manager
ignore_in_report: true
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16319) in GitLab 18.3 [with the feature flags](../../../development/feature_flags/_index.md) `secrets_manager` and `ci_tanukey_ui`. Disabled by default.
- Feature flag `ci_tanukey_ui` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/549940) in GitLab 18.4.
- Made available to some users in a closed beta in GitLab 18.8.
- Group secrets manager [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17904) and made available to closed beta users in 18.10 [with the feature flag](../../../development/feature_flags/_index.md) `group_secrets_manager`.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/21731) from closed beta to public beta in GitLab 19.0.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/10723) to limited availability on GitLab.com in GitLab 19.3.
- Default read and write permissions for the Maintainer role in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/623437) in GitLab 19.4.
- Default read metadata and create permissions for the Developer role in projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/623438) in GitLab 19.5.
- Secrets permissions for groups [removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/623457) in GitLab 19.4. Group permissions no longer grant access, and the `GROUP` principal type, the `groupPath` argument of `PrincipalInput`, and the `group` field of `Principal` were removed from the GraphQL API. Grant permissions to users or roles instead.
- Feature flags `secrets_manager` and `group_secrets_manager` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/259222) in GitLab 19.5.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/work_items/17903) in GitLab 19.5.

{{< /history >}}

Use GitLab Secrets Manager to encrypt, store, and retrieve credentials securely
for your projects and groups, powered by [OpenBao](https://openbao.org/).
Instead of hardcoding credentials or relying on CI/CD variables,
you can retrieve secrets with [full auditability](../../../user/compliance/audit_event_types.md#secrets-management) using the GitLab access model and audit system.

Secrets represent sensitive information your CI/CD jobs need to function,
such as access tokens, database credentials, or private keys.
Unlike CI/CD variables, which are always available to jobs by default,
secrets must be explicitly requested by a job.

You can [use secrets in CI/CD jobs](#use-secrets-in-job-scripts) or [outside of CI/CD for runtime workloads](non_cicd_access.md), such as Kubernetes, Terraform, or through the API.

GitLab Secrets Manager [consumes GitLab Credits](credit_usage.md).

Share your feedback in [issue 598100](https://gitlab.com/gitlab-org/gitlab/-/work_items/598100).

## Enable GitLab Secrets Manager

On GitLab.com, you enable GitLab Secrets Manager for a top-level group.
All subgroups and projects in that group can then use the Secrets Manager.

On GitLab Self-Managed, an administrator enables the Secrets Manager for the instance.
All groups and projects on the instance can then use the Secrets Manager.

After the Secrets Manager is enabled, you can [create secrets](#define-a-secret) in any of those groups and projects.

### For GitLab.com

#### Enable with GitLab Credits

{{< history >}}

- **Enable with GitLab Credits** option [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254349) in GitLab 19.4.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the top-level group.

To enable GitLab Secrets Manager with GitLab Credits:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Secure** > **Secrets manager**.
1. Select **Enable with GitLab Credits**.
1. In the confirmation dialog, select **Enable GitLab Secrets Manager**.

If your subscription has no GitLab Credits available, the subscription owner must first purchase a monthly commitment
or accept on-demand billing in the Customers Portal.

#### Start a trial

Alternatively, you can [start a 30-day trial](credit_usage.md#on-gitlabcom) to try GitLab Secrets Manager with temporary evaluation credits.
After the trial expires, GitLab Secrets Manager starts consuming GitLab credits.
To avoid a service interruption, purchase a monthly commitment pool of credits or
accept the usage billing terms before the trial ends.

### For GitLab Self-Managed

Only an administrator can enable or disable the Secrets Manager, and the setting applies to the whole instance.
Until the Secrets Manager is enabled, the **Secrets manager** item does not appear in the left sidebar.

When you enable GitLab Secrets Manager for the instance, all groups and projects on the instance can use the Secrets Manager.

Prerequisites:

- Administrator access.
- OpenBao must be [installed and configured](../../../administration/secrets_manager/_index.md#install-openbao).
- You must have a Premium or Ultimate subscription.

With an online license, you can start a trial or enable with GitLab Credits.
If your instance uses an offline license, see [enable with an offline license](#enable-with-an-offline-license).

#### Start a trial

For information about the trial credits, when the trial ends, and the steps to start a trial, see
[start a trial on GitLab Self-Managed](credit_usage.md#on-gitlab-self-managed).

#### Enable with GitLab Credits

Prerequisites:

- Your instance must have an online cloud license.
- Your subscription must have GitLab Credits available, through a monthly commitment
  or on-demand billing accepted in the Customers Portal.

To enable GitLab Secrets Manager with GitLab Credits:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Secrets Manager**.
1. Select **Enable with GitLab Credits**.
1. In the confirmation dialog, select **Enable GitLab Secrets Manager**.

#### Enable with an offline license

Offline instances cannot start a trial or use **Enable with GitLab Credits**.
Instead, you turn on the **Secrets Manager** toggle.

Your offline license must include GitLab Secrets Manager.

To enable GitLab Secrets Manager:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Secrets Manager**.
1. Turn on the **Secrets Manager** toggle.

If your license does not include GitLab Secrets Manager, the toggle is disabled and the section shows an alert.
Contact the subscription owner to purchase a license.

## Define a secret

You can add secrets to the secrets manager so that it can be used for secure CI/CD pipelines
and workflows.

Secrets defined for a project can only be accessed by pipelines from the same project.
Secrets defined for a group can only be accessed by pipelines in a project directly under the group
or in its subgroup hierarchy.

1. In the top bar, select **Search or go to** and find your project or group.
1. Select **Secure** > **Secrets manager**.
1. Select **New secret** and fill in the details:
   - **Name**: Must be unique in the project or group where it's created, 255 characters or fewer, and contain only letters,
     digits, and underscores (`_`). You cannot change the name after you create the secret.
   - **Value**: Must be 10 KB (10,000 bytes) or less.
   - **Description**: Maximum of 200 characters.
   - **Environments**: Can be:
     - **All (default)** (`*`)
     - A specific [environment](../../environments/_index.md#types-of-environments).
     - A [wildcard environment](../../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Branches**: Option only exists in project settings. Can be:
     - A specific branch.
     - A wildcard branch (must have the `*` character).
   - **Protected Branches**: Option only exists in group settings. Optional. Export secrets to pipelines running on protected branches only.
   - **Rotation reminder period**: Optional. Send an email reminder to rotate the secret after the set number of days.
     Minimum 7 days.
1. Select **Add secret**.

[By default](../../../administration/instance_limits.md#secrets-manager-limits),
you can store a maximum of 100 secrets per project, and 500 per group. Secrets in a subgroup or
in a member project do not count toward the limit of a parent group.

After you create a secret:

- You can use it in the pipeline configuration or in job scripts.
- If you edit the secret, you can only overwrite the value with a new value.
  You cannot retrieve the secret value through the UI. For more information, review the
  [permissions for GitLab Secrets Manager](../../../user/permissions.md#project-secrets-manager).

> [!warning]
> The value of a secret is accessible to all CI/CD pipeline jobs running for the specific environment or branch
> defined when the secret is created or updated. Ensure only users with permission to access
> the value of these secrets can run jobs for the specified environment or branch.

## Use secrets in job scripts

By default, similar to [file type CI/CD variables](../../variables/_index.md#use-file-type-cicd-variables),
a secret is made available in a job as a file with an associated environment variable:

- The secret's key is the environment variable name.
- The secret's value is saved to a temporary file. Unlike masked CI/CD variables, secrets can have spaces and newlines.
- The path to the temporary file is the environment variable value.

Use a secret in job scripts with commands that accept files as inputs, or optionally
directly [use the secret as an environment variable](#use-a-secret-as-an-environment-variable-with-file-false).

If a job outputs a secret's value, GitLab replaces the value in the job log with `[MASKED]`.

### For project secrets

Prerequisites:

- GitLab Runner 19.0 or later.

To access secrets stored in the Secret Manager for a project, use the [`secrets`](../../yaml/_index.md#secrets)
and `gitlab_secrets_manager` keywords.

For example:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube_cert
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### For group secrets

Prerequisites:

- GitLab Runner 19.0 or later.

To access secrets stored in the Secret Manager for a group:

- Use the [`secrets`](../../yaml/_index.md#secrets) and `gitlab_secrets_manager` keywords.
- Specify the group as a secret manager source by using the `source` field with the `group/` prefix followed by the `<full-path-to-group>`.

For example:

```yaml
job:
  secrets:
    KUBE_CA_PEM:
      gitlab_secrets_manager:
        name: kube_cert
        source: group/my-group/my-subgroup
  script:
   - kubectl config set-cluster e2e --server="https://example.com" --certificate-authority="$KUBE_CA_PEM"
```

### Use a secret as an environment variable with `file: false`

To use a secret as an environment variable and not have it stored in a file,
set `file: false` for the secret. For example:

```yaml
job:
  secrets:
    DEPLOY_SECRET:
      gitlab_secrets_manager:
        name: deploy_credentials
      file: false
  script:
    - my_deploy_command --user username --pass $DEPLOY_SECRET
```

In this example, the secret is made available to the job as the `DEPLOY_SECRET` variable,
which you can use like any other environment variable.

## Secret rotation notifications

Users with the Owner role in the project receive an email notification to rotate a secret on the day specified in a secret's configuration.

## Access secrets from non-CI/CD workloads

Workloads that do not run as GitLab CI/CD jobs can read secrets through the Secrets Manager API.
For more information, see [Access secrets from non-CI/CD workloads](non_cicd_access.md).

## Manage secrets permissions

### For a project

Prerequisites:

- You must have the Owner role for the project to manage the secrets permissions.
- Users with the Maintainer role for the project can view the defined permissions.
- GitLab Secrets Manager must be enabled.

To update the secrets permissions for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Visibility, project features, permissions**.
1. Under **GitLab Secrets Manager**, in the **User permissions** section:
   - Select **Add** to add permissions rules for specific users or roles.
   - You can set permission scopes to read metadata, read value, write (create & update), and delete secrets.
   - Optional. Set an **Access expiration date** to make the permissions expire.

For secrets managers enabled in GitLab 19.4 and later, users with the Maintainer role for the project have the
read and write (create & update) permissions by default.

Users with the Developer role for the project have the read metadata and create permissions by default.
The create permission does not include update, so these users can add secrets
but cannot change secrets that already exist.

Users with the Owner role can remove or change these default permissions.

### For a group

{{< history >}}

- Top-level group setting [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/605581) from **Settings** > **General** to **Settings** > **Secure** in GitLab 19.4

{{< /history >}}

Prerequisites:

- You must have the Owner role for the group to manage the secrets permissions.
  Only users with the Owner role for the group can view the defined permissions.
- GitLab Secrets Manager must be enabled.

To update the secrets permissions for a group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar:
   - In a top-level group, select **Settings** > **Secure**.
   - In a subgroup, select **Settings** > **General** and expand **Permissions and group features**.
1. Under **GitLab Secrets Manager**, in the **User permissions** section:
   - Select **Add** to add permissions rules for specific users or roles.
   - You can set permission scopes to read metadata, read value, write (create & update), and delete secrets.
   - Optional. Set an **Access expiration date** to make the permissions expire.

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

## Disable GitLab Secrets Manager

When you disable GitLab Secrets Manager:

- Jobs or workloads that fetch secrets stop working.
- GitLab does not delete your secrets.
- Project and group members can only view details or delete existing secrets.
- The Secrets Manager does not consume GitLab Credits.

If you started a trial, you can enable the Secrets Manager again at any time before the trial ends.

### Disable on GitLab.com

Prerequisites:

- You must have the Owner role for the top-level group.

To disable GitLab Secrets Manager:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Settings** > **Secure**.
1. In the **GitLab Secrets Manager** section, turn off the toggle.
1. In the confirmation dialog, select **Disable**.

To enable the Secrets Manager again, turn the toggle back on.

### Disable on GitLab Self-Managed

Disabling the Secrets Manager applies to all groups and projects on the instance.
With an offline license that includes the add-on, GitLab stops billing for the Secrets Manager.

Prerequisites:

- Administrator access.

To disable GitLab Secrets Manager:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Secrets Manager**.
1. Turn off the **Secrets Manager** toggle.
1. In the confirmation dialog, select **Disable**.

## Related topics

- [GitLab Secrets Manager credit usage](credit_usage.md)
- [Secret Audit Tool for Variables](https://gitlab.com/guided-explorations/secrets-management/secret-audit-tool-for-variables):
  A community tool that scans a GitLab group hierarchy for CI/CD variables whose names suggest they may hold credentials
  (passwords, tokens, API keys, and similar). It generates an HTML report to help you identify
  variables to migrate to GitLab Secrets Manager.

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

To resolve this error, create a secret in the project or group.
Then re-run the pipeline.

### Error: `namespace does not have access to GitLab Secrets Manager`

Jobs that request secrets from GitLab Secrets Manager fail with this error before a runner
picks them up when the namespace does not have access to GitLab Secrets Manager.

#### GitLab.com

Possible causes on GitLab.com:

- The trial has expired.
- The group has no GitLab credits available.
- On-demand billing is turned off.
- The subscription grace period has expired.
- The open beta has ended and the namespace did not opt in.

To restore access for the top-level group, start a free trial or
[enable GitLab Secrets Manager with GitLab Credits](#enable-with-gitlab-credits).
The subscription must have GitLab Credits available through a monthly commitment
or on-demand billing. If the subscription has lapsed, renew it. For more
information, see [GitLab Secrets Manager usage and billing](secrets_manager_billing.md).

#### GitLab Self-Managed

On GitLab Self-Managed, GitLab resolves access to Secrets Manager at the instance
level, not per group.

Possible causes:

- The instance is using a trial license. Secrets Manager trials are only available with a paid subscription.
- The Secrets Manager trial has expired.
- The instance subscription does not include GitLab Secrets Manager.
- The subscription grace period has expired.
- For offline licenses, the license does not include an active GitLab Secrets Manager add-on.

To restore access, ask an instance administrator to add GitLab Secrets Manager to the
instance subscription. Instances with a paid subscription can also start a free trial.
