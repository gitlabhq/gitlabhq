---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: SSH key limits, 2FA, tokens, hardening.
title: Secure GitLab
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## General information

This section covers general information and recommendations about the platform.

- [Password and OAuth token storage](password_storage.md)
- [Password generation for users created through integrated authentication](passwords_for_integrated_authentication_methods.md)
- [CRIME vulnerability management](crime_vulnerability.md)
- [Secret rotation for third-party integrations](rotate_integrations_secrets.md)

## Recommendations

For more information about improving the security posture of your GitLab environment, see the [hardening recommendations](hardening.md).

### Antivirus software

Generally, running an antivirus software on the GitLab host is not recommended.

However, if you must use one, all of the location of GitLab on the system should be excluded from scanning as it could be quarantined as a false positive.

Specifically, you should exclude the following GitLab directories from scanning:

- `/var/opt/gitlab`
- `/etc/gitlab/`
- `/var/log/gitlab/`
- `/opt/gitlab/`

You can find all those directories listed in the [Linux package configuration documentation](https://docs.gitlab.com/omnibus/settings/configuration.html).

### User accounts

- [Review authentication options](../administration/auth/_index.md).
- [Configure password length limits](password_length_limits.md).
- [Restrict SSH key technologies and require minimum key lengths](ssh_keys_restrictions.md).
- [Restrict account creation with sign up restrictions](../administration/settings/sign_up_restrictions.md).
- [Send email confirmation on sign-up](user_email_confirmation.md)
- [Enforce two-factor authentication](two_factor_authentication.md) to require users to [enable two-factor authentication](../user/profile/account/two_factor_authentication.md).
- [Restrict logins from multiple IPs](../administration/reporting/ip_addr_restrictions.md).
- [How to reset a user password](reset_user_password.md).
- [How to unlock a locked user](unlock_user.md).

### Data access

- [Security considerations for project membership](../user/project/members/_index.md#security-considerations).
- [Protecting and removing user file uploads](user_file_uploads.md).
- [Proxying linked images for user privacy](asset_proxy.md).

### Platform usage and settings

- [Review GitLab token type and usages](tokens/_index.md).
- [How to configure rate limits improve security and availability](rate_limits.md).
- [How to filter outbound webhook requests](webhooks.md).
- [How to configure import and export limits and timeouts](../administration/settings/import_and_export_settings.md).
- [Review Runner security considerations and recommendations](https://docs.gitlab.com/runner/security/).
- [Review CI/CD variables security considerations](../ci/variables/_index.md#cicd-variable-security).
- [Review pipeline security for usage and protection of secrets in CI/CD Pipelines](../ci/pipeline_security/_index.md).
- [Instance-wide compliance and security policy management](compliance_security_policy_management.md).

### Patching

GitLab Self-Managed customers and administrators are responsible for the security of their underlying hosts, and for keeping GitLab itself up to date. It is important to [regularly patch GitLab](../policy/maintenance.md), patch your operating system and its software, and harden your hosts in accordance with vendor guidance.

## Monitoring

### Logs

- [Review the log types and contents produced by GitLab](../administration/logs/_index.md).
- [Review Runner job logs information](../administration/cicd/job_logs.md).
- [How to use correlation ID to trace logs](../administration/logs/tracing_correlation_id.md).
- [Logging configuration and access](https://docs.gitlab.com/omnibus/settings/logs.html).
- [How to configure audit event streaming](../administration/compliance/audit_event_streaming.md).

## Response

- [Responding to security incidents](responding_to_security_incidents.md).

## Rate limits

For information about rate limits, see [Rate limits](rate_limits.md).
