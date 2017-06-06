# Audit Events

GitLab Enterprise Edition offers a way to view the changes made within the GitLab server as a help to system administrators.

GitLab system administrators can also take advantage of the logs located on the filesystem, see [the logs system documentation](logs.md) for more details.


# Security Events

| Security Event                 | Description                                                                                      |
|--------------------------------|--------------------------------------------------------------------------------------------------|
| User added to group or project | Notes the author of the change, target user                                                      |
| User permission changed        | Notes the author of the change, original permission and new permission, target user              |


# Audit Events in Project

To view the Audit Events user needs to have enough permissions to view the project Settings page.

Navigate to Project->Settings->Audit Events to view the Audit Events:

![audit events project](audit_events_project.png)

# Audit Events in Group

To view the Audit Events user needs to have enough permissions to view the group Settings page.

Navigate to Group->Settings->Audit Events to view the Audit Events:

![audit events group](audit_events_group.png)

# Audit Log (Admin only)

> **Notes:**
> [Introduced][ee-2336] in GitLab 9.3.

Server-wide audit logging, available in GitLab Enterprise Edition Premium since 9.3, introduces
the ability to observe user actions across the entire instance of your GitLab Server, making it
easy to understand who changed what and when for audit purposes.

To view the server-wide admin log, visit the Admin Area, select Monitoring and choose Audit Log.

It is possible to filter particular actions by choosing an audit data type from the filter drop-down.
You can further filter by specific group, project or user (for authentication events).

![audit log](audit_log.png)

[ce-23361]: https://gitlab.com/gitlab-org/gitlab-ee/issues/2336
