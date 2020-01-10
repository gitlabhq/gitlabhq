---
last_updated: 2019-09-16
---

# Audit Events **(STARTER)**

GitLab offers a way to view the changes made within the GitLab server for owners and administrators on a [paid plan][ee].

GitLab system administrators can also take advantage of the logs located on the
filesystem, see [the logs system documentation](logs.md) for more details.

## Overview

**Audit Events** is a tool for GitLab owners and administrators to be
able to track important events such as who performed certain actions and the
time they happened. These actions could be, for example, change a user
permission level, who added a new user, or who removed a user.

## Use-cases

- Check who was the person who changed the permission level of a particular
  user for a project in GitLab.
- Use it to track which users have access to a certain group of projects
  in  GitLab, and who gave them that permission level.

## List of events

There are two kinds of events logged:

- Events scoped to the group or project, used by group / project managers
  to look up who made what change.
- Instance events scoped to the whole GitLab instance, used by your Compliance team to
  perform formal audits.

### Group events **(STARTER)**

NOTE: **Note:**
You need Owner [permissions] to view the group Audit Events page.

To view a group's audit events, navigate to **Group > Settings > Audit Events**.
From there, you can see the following actions:

- Group name/path changed
- Group repository size limit changed
- Group created/deleted
- Group changed visibility
- User was added to group and with which [permissions]
- Permissions changes of a user assigned to a group
- Removed user from group
- Project added to group and with which visibility level
- Project removed from group
- [Project shared with group](../user/project/members/share_project_with_groups.md)
  and with which [permissions]
- Removal of a previously shared group with a project
- LFS enabled/disabled
- Shared runners minutes limit changed
- Membership lock enabled/disabled
- Request access enabled/disabled
- 2FA enforcement/grace period changed
- Roles allowed to create project changed

Group events can also be accessed via the [Group Audit Events API](../api/audit_events.md#group-audit-events-starter)

### Project events **(STARTER)**

NOTE: **Note:**
You need Maintainer [permissions] or higher to view the project Audit Events page.

To view a project's audit events, navigate to **Project > Settings > Audit Events**.
From there, you can see the following actions:

- Added/removed deploy keys
- Project created/deleted/renamed/moved(transferred)/changed path
- Project changed visibility level
- User was added to project and with which [permissions]
- Permission changes of a user assigned to a project
- User was removed from project
- Project export was downloaded
- Project repository was downloaded
- Project was archived
- Project was unarchived
- Added/removed/updated protected branches
- Release was added to a project
- Release was updated
- Release milestone associations changed

### Instance events **(PREMIUM ONLY)**

> [Introduced][ee-2336] in [GitLab Premium][ee] 9.3.

Server-wide audit logging introduces the ability to observe user actions across
the entire instance of your GitLab server, making it easy to understand who
changed what and when for audit purposes.

To view the server-wide admin log, visit **Admin Area > Monitoring > Audit Log**.

In addition to the group and project events, the following user actions are also
recorded:

- Failed Logins
- Sign-in events and the authentication type (standard, LDAP, OmniAuth, etc.)
- Added SSH key
- Added/removed email
- Changed password
- Ask for password reset
- Grant OAuth access
- Started/stopped user impersonation

It is possible to filter particular actions by choosing an audit data type from
the filter drop-down. You can further filter by specific group, project or user
(for authentication events).

![audit log](img/audit_log.png)

Instance events can also be accessed via the [Instance Audit Events API](../api/audit_events.md#instance-audit-events-premium-only)

### Missing events

Some events are not being tracked in Audit Events. Please see the following
epics for more detail on which events are not being tracked and our progress
on adding these events into GitLab:

- [Project settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/474)
- [Group settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/475)
- [Instance-level settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/476)

### Disabled events

#### Repository push

The current architecture of audit events is not prepared to receive a very high amount of records.
It may make your project/admin audit logs UI very busy and the disk space consumed by the
`audit_events` Postgres table will increase considerably. Thus, it's disabled by default
to prevent performance degradations on GitLab instances with very high Git write traffic.

In an upcoming release, Audit Logs for Git push events will be enabled
by default. Follow [#7865](https://gitlab.com/gitlab-org/gitlab/issues/7865) for updates.

If you still wish to enable **Repository push** events in your instance, follow
the steps bellow.

**In Omnibus installations:**

1. Enter the Rails console:

   ```sh
   sudo gitlab-rails console
   ```

1. Flip the switch and enable the feature flag:

   ```ruby
   Feature.enable(:repository_push_audit_event)
   ```

[ee-2336]: https://gitlab.com/gitlab-org/gitlab/issues/2336
[ee]: https://about.gitlab.com/pricing/
[permissions]: ../user/permissions.md
