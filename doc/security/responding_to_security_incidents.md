---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Responding to security incidents

When a security incident occurs, you should follow the processes defined by your organization. The GitLab SIRT team created this guide:

- For administrators and maintainers of self-managed GitLab instances and groups on GitLab.com.
- To provide additional information and best practices on how to respond to various security incidents related to GitLab services.
- As a supplement to the processes defined by your organization to handle security incidents. It is **not a replacement**.

Using this guide, you should feel confident in handling security incidents related to GitLab. Where necessary, the guide links to other parts of GitLab documentation.

WARNING:
Use the suggestions/recommendations mentioned in this guide at your own risk.

## Common breach scenarios

### Credential exposure to public internet

This scenario refers to security events where sensitive authentication or authorization information has been exposed to the Internet due to misconfigurations or human errors. Such information might include:

- Passwords.
- Personal access tokens.
- Project access tokens.
- Runner tokens.
- Pipeline trigger tokens.
- SSH keys.

This scenario might also include the exposure of sensitive information about third-party credentials through GitLab services. The exposure could occur through accidental commits to public GitLab projects or misconfiguration of CI/CD settings. For more information, see:

- [Overview of GitLab tokens](token_overview.md)
- [GitLab CI/CD variable security](../ci/variables/index.md#cicd-variable-security)

#### Response

Security incidents related to credentials exposure can vary in severity from low to critical, depending on the type of token and its associated permissions. When responding to such incidents, you should:

- Determine the type and scope of the token.
- Identify the token owner and the relevant team based on the token information.
- Revoke the token after you have assessed its scope and potential impact. Revoking a production token might cause service interruption while not revoking an admin token, can cause harm, too, so only revoke the token if you are:
  - Confident in the potential impact.
  - Following your company's security incident response guidelines.
- Document the time of credential exposure and the time when you revoked the credentials.
- Review GitLab audit logs to identify any unauthorized activity associated with the exposed token. Depending on the scope and type of token, search for audit events related to newly created users, tokens, run malicious pipelines,changes to code and changes to project settings.

#### Event types

- Review the available [audit events](../administration/audit_event_reports.md) for your group or namespace.
- Adversaries may attempt to create tokens, SSH keys, or user accounts to maintain persistence. Look for [audit events](../user/compliance/audit_event_types.md) related to these activities.
- Focus on CI-related [audit events](../user/compliance/audit_event_types.md#continuous-integration) to identify any modifications to CI/CD variables.
- Review [job logs](../administration/job_logs.md) for any pipelines ran by an adversary

### Suspected compromised user account

#### Response

If you suspect that a user account or bot account has been compromised, you should:

- [Block the user](../administration/moderate_users.md#block-a-user) to mitigate any current risk.
- Reset any credentials the user might have had access to. For example, users with at least the Maintainer role can view protected [CI/CD variables](../ci/variables/index.md) and [runner registration tokens](../security/token_overview.md#runner-registration-tokens-deprecated).
- [Reset the user's password](../security/reset_user_password.md).
- Get the user to [enable two factor authentication](../user/profile/account/two_factor_authentication.md) (2FA), and consider [enforcing 2FA at the instance or group level](two_factor_authentication.md).
- After completing an investigation and mitigating impacts, unblock the user.

#### Event types

Review the [audit events](../administration/audit_event_reports.md) available to you to identify any suspicious account behavior. For example:

- Suspicious sign-in events.
- Creation or deletion of personal, project, and group access tokens.
- Creation or deletion of SSH or GPG keys.
- Creation, modification, or deletion of two-factor authentication.
- Changes to repositories.
- Changes to group or project configurations.
- Addition or modification of runners.
- Addition or modification of webhooks or Git hooks.
- Addition or modification of authorized OAuth applications.
- Changes to connected SAML identity providers.
- Changes to email addresses or notifications.

### CI/CD-related security incidents

CI/CD workflows are an integral part of modern day software development and primarily used by developers and SREs to build, test and deploy code to production. Because these workflows are attached to the production environments, they often require access to sensitive secrets within the CI/CD pipelines. Security incidents related to CI/CD might vary based on your setup, but they can be broadly classified as follows:

- Security incidents related to exposed GitLab CI/CD job tokens.
- Secrets exposed through misconfigured GitLab CI/CD.

#### Response

##### Exposed GitLab CI/CD job token

When a pipeline job is about to run, GitLab generates a unique token and injects it as the `CI_JOB_TOKEN` [predefined variable](../ci/variables/predefined_variables.md). You can use a GitLab CI/CD job token to authenticate with specific API endpoints. This token has the same permissions to access the API as the user that caused the job to run. The token is valid only while the pipeline job runs. After the job finishes, the token expires and can no longer be used.

Under normal circumstances, the `CI_JOB_TOKEN` is not displayed in the job logs. However, enabling verbose logging in a pipeline, running commands that echo shell environment variables to the console, or failing to properly secure runner infrastructure can expose this data unintentionally. In such instances, you should:

- Check if there are any recent modifications to the source code in the repo. You can check the commit history of the modified file to determine the actor who made the changes. If you suspect suspicious edits, investigate the user activity using the [suspected compromised user account guide](#suspected-compromised-user-account).
- Any suspicious modification to any code that is called by that file can cause issues and should be investigated and may lead to exposed secrets.
- Consider rotating the exposed secrets after determining the production impact of revocation.
- Review [audit logs](../administration/audit_event_reports.md) available to you for any suspicious modifications to user and project settings.

##### Secrets exposed through misconfigured GitLab CI/CD

When secrets stored as CI variables are not [masked](../ci/variables/index.md#mask-a-cicd-variable), they might be exposed in the job logs. For example, echoing environment variables or encountering a verbose error message. Depending on the project visibility, the job logs might be accessible within your company or over the Internet if your project is public. To mitigate this type of security incident, you should:

- Revoke exposed secrets by following the [exposed secrets guide](#credential-exposure-to-public-internet).
- Consider masking the variables. This will prevent them from being directly reflected within the job logs. However, masking is not full-proof. For example, a masked variable may still be written to an artifact file or sent to a remote system.
- Consider protecting the variables. This will ensure they are available only in protected branches.
- Consider disabling public pipelines to prevent public access to job logs and artifacts.
- Review artifact retention and expiration polices.
- Follow the CI/CD [jobs token security guide](../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security) for more information around best practices.
- Review audit logs for the exposed secrets systems such as CloudTrail logs for AWS or CloudAudit Logs for GCP to determine if any suspicious changes were made at the time of exposure.
- Review audit logs available to you for any suspicious modifications to user and project settings.

### Suspected compromised instance

Self-managed GitLab customers and administrators are responsible for:

- The security of their underlying infrastructure.
- Keeping GitLab itself up to date.

It is important to [regularly update GitLab](../policy/maintenance.md), update your operating system and its software, and harden your hosts in accordance with vendor guidance.

#### Response

If you suspect that your GitLab instance has been compromised, you should:

- Review the [audit events](../administration/audit_event_reports.md) available to you for suspicious account behavior.
- Review [all users](../administration/moderate_users.md) (including the Administrative root user), and follow the steps in the [suspected compromised user account guide](#suspected-compromised-user-account) if necessary.
- Review the Credentials Inventory, if available to you.
- Change any sensitive credentials, variables, tokens, and secrets. For example, those located in instance configuration, database, CI/CD pipelines, or elsewhere.
- Update to the latest version of GitLab and adopt a plan to update after every security patch release.
- In addition, the following suggestions are common steps taken in incident response plans when servers are compromised by malicious actors.
- Save any server state and logs to a write-once location, for later investigation.
- Look for unrecognized background processes.
- Check for open ports on the system.
- Rebuild the host from a known-good backup or from scratch, and apply all the latest security patches.
- Review network logs for uncommon traffic.
- Establish network monitoring and network-level controls.
- Restrict inbound and outbound network access to authorized users and servers only.
- Ensure all logs are routed to an independent write-only datastore.

#### Event types

Review [system access audit events](../user/compliance/audit_event_types.md#system-access) to determine any changes related to system settings, user permissions and user login events.

### Misconfigured project or group settings

Security incidents can occur as a result of improperly configured project or group settings, potentially leading to unauthorized access to sensitive or proprietary data. These incidents may include but are not limited to:

- Changes in project visibility.
- Modifications to MR approval settings.
- Project deletions.
- Addition of suspicious webhooks to projects.
- Changes in protected branch settings.

#### Response

If you suspect unauthorized modifications to project settings, consider taking the following steps:

- Begin by reviewing the available [audit events](../administration/audit_event_reports.md) to identify the user responsible for the action.
- If the user account appears suspicious, follow the steps outlined in the [suspected compromised user account guide](#suspected-compromised-user-account).
- Consider reverting the settings to their original state by referring to the audit events and consulting the project owners and maintainers for guidance.

#### Event types

- Audit logs can be filtered based on the `target_type` field. Based on the security incident context, apply a filter to this field to narrow down the scope.
- Look for specific audit events of [compliance management](../user/compliance/audit_event_types.md#compliance-management) and [audit events of groups and projects](../user/compliance/audit_event_types.md#groups-and-projects).

### Engaging GitLab for assistance with a security incident

Before you ask GitLab for help, search the [GitLab documentation](https://docs.gitlab.com/). You should engage support once you have performed the preliminary investigation on your end and have additional questions or need of assistance. Eligibility for assistance from GitLab Support is [determined by your license](https://about.gitlab.com/support/#gitlab-support-service-levels).

### Security Best Practices

Review the [GitLab Security documentation](index.md) for what suggestions will work best for your environment and needs.

### Detections

GitLab SIRT maintains an active repository of useful detections in the GitLab SIRT public project(`https://gitlab.com/gitlab-com/gl-security/security-operations/gitlab-sirt-public/automated-incident-response/-/tree/main/detections?ref_type=heads`).

The detections in this repository are based on the audit events and in the general Sigma rule format. You can use sigma rule converter to get the rules in your desired format. Please refer to the repo for more information about Sigma format and tools related to it . Make sure you have GitLab audit logs ingested to your SIEM. You should follow the [audit event streaming guide](../administration/audit_event_streaming/index.md) to stream audit events to your desired destination.
