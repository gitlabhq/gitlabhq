---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Comparison of GitLab self-managed with GitLab SaaS

GitLab SaaS is the largest hosted instance of GitLab in the world, managed by an
[all-remote team](https://about.gitlab.com/company/culture/all-remote/) that knows GitLab best. With GitLab SaaS, updates, maintenance, and patches are all performed by this team.

Self-managed GitLab gives you a deeper breadth of control over many of the functions and systems of the application.

## Administration

In GitLab SaaS, administration tasks are limited compared to a self-managed application.

In a self-managed instance:

- You have complete access and administrative control over the application, including the [Admin Area](../../user/admin_area/settings/index.md).
- You can impersonate, create, add, and remove users.
- You can assign the [`Auditor`](../../administration/auditor_users.md) user type and `External` role.

On GitLab SaaS:

- You have limited administrative control. For example, you cannot impersonate, create, add, or remove users.
- You cannot access the [Admin Area](../../user/admin_area/settings/index.md).
- You cannot assign the `Auditor` user type and `External` role.

## Logs

Logs give insight into your processes and can help GitLab Support maintain your application and resolve problems.

In a self-managed instance:

- You have full access to system logs.

On GitLab SaaS:

- You do not have access to system logs because they are at the instance level, and managed by the GitLab [infrastructure team](https://about.gitlab.com/handbook/engineering/infrastructure/).
- You can view [Audit Events](../../administration/audit_events.md) and the [GitLab API](../../api/audit_events.md).
- You must [request audit information](https://about.gitlab.com/handbook/support/workflows/log_requests.html) from the Support team.

## Runners

Runners are available for both SaaS and self-managed applications.

In a self-managed instance, your runner availability and options are broader, but there are more [security concerns](https://docs.gitlab.com/runner/security/#security-for-self-managed-runners) to consider.

On GitLab SaaS:

- Private [runners](../../ci/runners/index.md) are available for GitLab SaaS [groups](../../user/group/index.md) and [projects](../../user/project/index.md).
- Shared runners provided by GitLab SaaS are not configurable. Each runner instance is used once for only one job, ensuring any sensitive data left on the system is destroyed after the job is complete.
- Shared runners are subject to usage limits and are [plan specific](https://about.gitlab.com/pricing/).

## Custom Git hooks

In a self-managed instance you can use any custom Git hooks.

On GitLab SaaS:

- SaaS users do not have access to the file system, and cannot use custom Git hooks.
- You can use [webhooks](../../user/project/integrations/webhooks.md) as an alternative.

## API and GraphQL

In a self-managed instance, users can access all API endpoints, including those that require instance `admin` permissions.

On GitLab SaaS:

- SaaS users have access to all of the [API endpoints](../../api/rest/index.md) except those that require instance `admin` permissions.
- Only authorized GitLab engineers have administrative access.

## Authentication

In a self-managed instance:

- You can use an internal encryption key for your data store.
- You can view console logs.
- You can enforce jobs on every pipeline across the group or organization.
- You have control over your data backup.
- You can use the [Interactive Web Terminal](../../ci/interactive_web_terminal/index.md#interactive-web-terminals) for shared runners.

On GitLab SaaS:

- You cannot use internal encryption key for the data store ([bring-your-own-key](https://about.gitlab.com/handbook/security/threat-management/vulnerability-management/encryption-policy.html#rolling-your-own-crypto)).
- You cannot view console logs.
- You cannot enforce jobs on every pipeline across the group or organization.
- You cannot configure or control data backups. You must use [group](../../api/group_import_export.md) and [project](../../api/project_import_export.md) export.
- The [Interactive Web Terminal](../../ci/interactive_web_terminal/index.md#interactive-web-terminals) is not available for shared runners.

## Public or private projects

Project privacy is different when using a self-managed application or GitLab SaaS.

In a self-managed instance, you control who can view your projects.

On GitLab SaaS:

- The GitLab SaaS instance is open to the public.
- When your projects are set as `Public`, they are open to everyone on the public internet.

## Encryption

In a self-managed instance, you control the encryption type and configuration.

On GitLab SaaS:

- An [Access Management Process](https://about.gitlab.com/handbook/security/#access-management-process) is in place.
- All data on GitLab.com is encrypted at rest by default. Access to encryption keys is strictly managed by GitLab.
- GitLab does not access your tenant data except as part of a verified service request from you.

## Support

In a self-managed instance:

- You can access any of your back-end systems.
- Our Support team can request logs to assist you.

On GitLab SaaS:

- For your privacy and security, there is no public access to GitLab back-end systems.
- Support staff work with [Site Reliability Engineers](https://about.gitlab.com/job-families/engineering/infrastructure/site-reliability-engineer/) to support the [infrastructure](https://about.gitlab.com/handbook/engineering/infrastructure/).
- GitLab Support can access instance logs and view projects, as well as impersonate users. The Support Team can access your logs.
