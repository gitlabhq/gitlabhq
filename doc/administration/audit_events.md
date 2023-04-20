---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit events **(PREMIUM)**

Use audit events to track important events, including who performed the related action and when.
You can use audit events to track, for example:

- Who changed the permission level of a particular user for a GitLab project, and when.
- Who added a new user or removed a user, and when.

Audit events are similar to the [log system](logs/index.md).

The GitLab API, database, and `audit_json.log` record many audit events. Some audit events are only available through
[streaming audit events](audit_event_streaming.md).

You can also generate an [audit report](audit_reports.md) of audit events.

NOTE:
You can't configure a retention policy for audit events, but epic
[7917](https://gitlab.com/groups/gitlab-org/-/epics/7917) proposes to change this.

## Time zones

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/242014) in GitLab 15.7, GitLab UI shows dates and times in the user's local time zone instead of UTC.

The time zone used for audit events depends on where you view them:

- In GitLab UI, your local time zone (GitLab 15.7 and later) or UTC (GitLab 15.6 and earlier) is used.
- The [Audit Events API](../api/audit_events.md) returns dates and times in UTC by default, or the
  [configured time zone](timezone.md) on a self-managed GitLab instance.
- In `audit_json.log`, UTC is used.
- In CSV exports, UTC is used.

## View audit events

Depending on the events you want to view, at a minimum you must have:

- For group audit events of all users in the group, the Owner role for the group.
- For project audit events of all users in the project, the Maintainer role for the project.
- For group and project audit events based on your own actions, the Developer role for the group or project.
- [Auditor users](auditor_users.md) can see group and project events for all users.

You can view audit events scoped to a group or project.

To view a group's audit events:

1. Go to the group.
1. On the left sidebar, select **Security and Compliance > Audit Events**.

Group events do not include project audit events. Group events can also be accessed using the
[Group Audit Events API](../api/audit_events.md#group-audit-events). Group event queries are limited to a maximum of 30
days.

To view a project's audit events:

1. Go to the project.
1. On the left sidebar, select **Security & Compliance > Audit Events**.

Project events can also be accessed using the [Project Audit Events API](../api/audit_events.md#project-audit-events).
Project event queries are limited to a maximum of 30 days.

## View instance audit events **(PREMIUM SELF)**

You can view audit events from user actions across an entire GitLab instance.

To view instance audit events:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Monitoring > Audit Events**.

### Export to CSV

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1449) in GitLab 13.4.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/285441) in GitLab 13.7.

You can export the current view (including filters) of your instance audit events as a CSV file. To export the instance
audit events to CSV:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Monitoring > Audit Events**.
1. Select the available search [filters](#filter-audit-events).
1. Select **Export as CSV**.

The exported file:

- Is sorted by `created_at` in ascending order.
- Is limited to a maximum of 100 000 events. The remaining records are truncated when this limit is reached.

Data is encoded with:

- Comma as the column delimiter.
- `"` to quote fields if necessary.
- New lines separate rows.

The first row contains the headers, which are listed in the following table along with a description of the values:

| Column               | Description                                        |
|:---------------------|:---------------------------------------------------|
| **ID**               | Audit event `id`.                                  |
| **Author ID**        | ID of the author.                                  |
| **Author Name**      | Full name of the author.                           |
| **Entity ID**        | ID of the scope.                                   |
| **Entity Type**      | Type of the scope (`Project`, `Group`, or `User`). |
| **Entity Path**      | Path of the scope.                                 |
| **Target ID**        | ID of the target.                                  |
| **Target Type**      | Type of the target.                                |
| **Target Details**   | Details of the target.                             |
| **Action**           | Description of the action.                         |
| **IP Address**       | IP address of the author who performed the action. |
| **Created At (UTC)** | Formatted as `YYYY-MM-DD HH:MM:SS`.                |

## View sign-in events **(FREE)**

Successful sign-in events are the only audit events available at all tiers. To see successful sign-in events:

1. Select your avatar.
1. Select **Edit profile > Authentication log**.

After upgrading to a paid tier, you can also see successful sign-in events on audit event pages.

## Filter audit events

From audit events pages, different filters are available depending on the page you're on.

| Audit event page | Available filter                                                                                                       |
|:-----------------|:-----------------------------------------------------------------------------------------------------------------------|
| Project          | User (member of the project) who performed the action.                                                                 |
| Group            | User (member of the group) who performed the action.                                                                   |
| Instance         | Group, project, or user.                                                                                               |
| All              | Date range buttons and pickers (maximum range of 31 days). Default is from the first day of the month to today's date. |

## User impersonation

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536) in GitLab 13.0.
> - Impersonation session events included in group audit events in GitLab 14.8.

When a user is [impersonated](../user/admin_area/index.md#user-impersonation), their actions are logged as audit events
with additional details:

- Audit events include information about the impersonating administrator. These audit events are visible in audit event
  pages depending on the audit event type (group, project, or user).
- Extra audit events are recorded for the start and end of the administrator's impersonation session. These audit events
  are visible as:
  - Instance audit events.
  - Group audit events for all groups the user belongs to. For performance reasons, group audit events are limited to
    the oldest 20 groups you belong to.

![Audit event with impersonated user](img/impersonated_audit_events_v15_7.png)

## Available audit events

You can view different events depending on the version of GitLab you have.

### Group events

The following actions on groups generate group audit events:

- Group name or path changed.
- Group repository size limit changed.
- Group created or deleted.
- Group changed visibility.
- User was added to group and with which [permissions](../user/permissions.md).
- User sign-in using [Group SAML](../user/group/saml_sso/index.md).
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8071) in GitLab 14.5, changes to the following
  [group SAML](../user/group/saml_sso/index.md) configuration:
  - Enabled status.
  - Enforcing SSO-only authentication for web activity.
  - Enforcing SSO-only authentication for Git and Dependency Proxy activity.
  - Enforcing users to have dedicated group-managed accounts.
  - Prohibiting outer forks.
  - Identity provider SSO URL.
  - Certificate fingerprint.
  - Default membership role.
  - SSO-SAML group sync configuration.
- Permissions changes of a user assigned to a group.
- Removed user from group.
- Project repository imported into group.
- [Project shared with group](../user/project/members/share_project_with_groups.md) and with which
  [permissions](../user/permissions.md).
- Removal of a previously shared group with a project.
- LFS enabled or disabled.
- Shared runners minutes limit changed.
- Membership lock enabled or disabled.
- Request access enabled or disabled.
- 2FA enforcement or grace period changed.
- Roles allowed to create project changed.
- Group CI/CD variable added, removed, or protected status changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30857) in GitLab 13.3.
- Compliance framework created, updated, or deleted.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340649) in GitLab 14.5.
- Event streaming destination created, updated, or deleted.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344664) in GitLab 14.6.
- Instance administrator started or stopped impersonation of a group member.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300961) in GitLab 14.8.
- Group deploy token was successfully created, revoked, or deleted.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353452) in GitLab 14.9.
- Failed attempt to create a group deploy token. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353452)
  in GitLab 14.9.
- [IP restrictions](../user/group/access_and_permissions.md#restrict-group-access-by-ip-address) changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358986) in GitLab 15.0.
- Changes to push rules. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227629) in GitLab 15.0.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356152) in GitLab 15.1, changes to the following merge
  request approvals settings:
  - Prevent approval by author.
  - Prevent approvals by users who add commits.
  - Prevent editing approval rules in projects and merge requests.
  - Require user password to approve.
  - Remove all approvals when commits are added to the source branch.
- Changes to streaming audit destination custom HTTP headers.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366350) in GitLab 15.3.
- Group had a security policy project linked, changed, or unlinked.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377877) in GitLab 15.6.
- An environment is protected or unprotected.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216164) in GitLab 15.8.
- Changes to Code Suggestions.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/405295) in GitLab 15.11.

### Project events

The following actions on projects generate project audit events:

- Added or removed deploy keys
- Project created, deleted, renamed, moved (transferred), changed path
- Project changed visibility level
- User was added to project and with which [permissions](../user/permissions.md)
- Permission changes of a user assigned to a project
- User was removed from project
- Project export was downloaded
- Project repository was downloaded
- Project was archived
- Project was unarchived
- Branch protection was added, removed, or updated
- Release was added to a project
- Release was updated
- Release was deleted. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/94793/) in GitLab 15.3.
- Release milestone associations changed
- Permission to approve merge requests by committers was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9.
- Permission to approve merge requests by committers was updated.
  - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9.
  - Message for event [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72623/diffs) in GitLab 14.6.
- Permission to approve merge requests by authors was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9.
- Number of required approvals was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9.
- Added or removed users and groups from project approval groups.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213603) in GitLab 13.2.
- Project CI/CD variable added, removed, or protected status changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30857) in GitLab 13.4.
- Project access token was successfully created or revoked.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230007) in GitLab 13.9.
- Failed attempt to create or revoke a project access token.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230007) in GitLab 13.9.
- When default branch changes for a project.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/52339) in GitLab 13.9.
- Created, updated, or deleted DAST profiles, DAST scanner profiles, and DAST site profiles.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217872) in GitLab 14.1.
- Changed a project's compliance framework.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/329362) in GitLab 14.1.
- User password required for approvals was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336211) in GitLab 14.2.
- Permission to modify merge requests approval rules in merge requests was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336211) in GitLab 14.2.
- New approvals requirement when new commits are added to an MR was updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336211) in GitLab 14.2.
- When [strategies for feature flags](../operations/feature_flags.md#feature-flag-strategies) are changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68408) in GitLab 14.3.
- Allowing force push to protected branch changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338873) in GitLab 14.3.
- Code owner approval requirement on merge requests targeting protected branch changed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338873) in GitLab 14.3.
- Users and groups allowed to merge and push to protected branch added or removed.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338873) in GitLab 14.3.
- Project deploy token was successfully created, revoked or deleted.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353451) in GitLab 14.9.
- Failed attempt to create a project deploy token.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353451) in GitLab 14.9.
- When merge method is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Merged results pipelines enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Merge trains enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Automatically resolve merge request diff discussions enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Show link to create or view a merge request when pushing from the command line enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Delete source branch option by default enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Squash commits when merging is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Pipelines must succeed enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Skipped pipelines are considered successful enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- All discussions must be resolved enabled or disabled.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Commit message suggestion is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/301124) in GitLab 14.9.
- Status check is added, edited, or deleted.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355805) in GitLab 15.0.
- Merge commit message template is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355805) in GitLab 15.0.
- Squash commit message template is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355805) in GitLab 15.0.
- Default description template for merge requests is updated.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355805) in GitLab 15.0.
- Project was scheduled for deletion due to inactivity.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) in GitLab 15.0.
- Project had a security policy project linked, changed, or unlinked.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377877) in GitLab 15.6.
- An environment is protected or unprotected.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216164) in GitLab 15.8.

### GitLab agent for Kubernetes events

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/382133) in GitLab 15.10.

GitLab generates audit events when a cluster agent token is created or revoked.

### Instance events **(PREMIUM SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16826) in GitLab 13.5, audit events for failed second-factor authentication attempt.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276250) in GitLab 13.6, audit events for when a user is approved using the Admin Area.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276921) in GitLab 13.6, audit events for when a user's personal access token is successfully or unsuccessfully created or revoked.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/298783) in GitLab 13.9, audit events for when a user requests access to an instance or is rejected using the Admin Area.

The following user actions on a GitLab instance generate instance audit events:

- Sign-in events and the authentication type such as standard, LDAP, or OmniAuth.
- Failed sign-ins.
- Added SSH key.
- Added or removed email.
- Changed password.
- Ask for password reset.
- Grant OAuth access.
- Started or stopped user impersonation.
- Changed username.
- User was added or deleted.
- User requests access to an instance.
- User was approved, rejected, or blocked using the Admin Area.
- User was blocked using the API.
- Failed second-factor authentication attempt.
- A user's personal access token was successfully or unsuccessfully created or revoked.
- Administrator added or removed. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323905) in GitLab 14.1.
- Removed SSH key. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220127) in GitLab 14.1.
- Added or removed GPG key. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220127) in GitLab 14.1.
- A user's two-factor authentication was disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238177) in
  GitLab 15.1.
- Enabled Admin Mode. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362101) in GitLab 15.7.
- All [group events](#group-events) and [project events](#project-events).
- User was unblocked using the Admin Area or API. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115727) in GitLab 15.11.
- User was banned using the Admin Area or API. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116103) in GitLab 15.11.
- User was unbanned using the Admin Area or API. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116221) in GitLab 15.11.

Instance events can also be accessed using the [Instance Audit Events API](../api/audit_events.md#instance-audit-events).

### GitLab Runner events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335509) in GitLab 14.8, audit events for when a runner is registered.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349540) in GitLab 14.9, audit events for when a runner is unregistered.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349542) in GitLab 14.9, audit events for when a runner is assigned to or unassigned from a project.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355637) in GitLab 15.0, audit events for when a runner registration token is reset.

GitLab generates audit events for the following GitLab Runner actions:

- Instance, group, or project runner is registered.
- Instance, group, or project runner is unregistered.
- Runner is assigned to or unassigned from a project.
- Instance, group, or project runner registration token is reset.
  [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102579) in GitLab 15.6.

## "Deleted User" events

Audit events created after users are deleted are created for "Deleted User". For example, if a deleted user's access to
a project is removed automatically due to expiration.

Issue [343933](https://gitlab.com/gitlab-org/gitlab/-/issues/343933) proposes to change this behavior.

## Unsupported events

Some events are not tracked in audit events. The following epics and issues propose support for more events:

- [Project settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/474).
- [Group settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/475).
- [Instance-level settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/476).
- [Deployment Approval activity](https://gitlab.com/gitlab-org/gitlab/-/issues/354782).
- [Approval rules processing by a non GitLab user](https://gitlab.com/gitlab-org/gitlab/-/issues/407384).

If you don't see the event you want in any of the epics, you can either:

- Use the **Audit Event Proposal** issue template to
  [create an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Audit%20Event%20Proposal) to
  request it.
- [Add it yourself](../development/audit_event_guide/index.md).
