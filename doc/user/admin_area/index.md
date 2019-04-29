# GitLab Admin Area **[CORE ONLY]**

The Admin Area provides a web UI for administering some features of GitLab self-managed instances.

To access the Admin Area, either:

- Click the Admin Area icon (the spanner or wrench icon).
- Visit `/admin` on your self-managed instance.

NOTE: **Note:**
Only admin users can access the Admin Area.

## Admin Area sections

The Admin Area is made up of the following sections:

| Section           | Description                                                                                                                                              |
|:------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------|
| Overview          | View your GitLab [Dashboard](#admin-dashboard), and maintain projects, users, groups, jobs, runners, and Gitaly servers.                                                     |
| Monitoring        | View GitLab system information, and information on background jobs, logs, [health checks](monitoring/health_check.md), request profiles, and audit logs. |
| Messages          | Send and manage [broadcast messages](broadcast_messages.md) for your users.                                                                              |
| System Hooks      | Configure [system hooks](../../system_hooks/system_hooks.md) for many events.                                                                            |
| Applications      | Create system [OAuth applications](../../integration/oauth_provider.md) for integrations with other services.                                            |
| Abuse Reports     | Manage [abuse reports](abuse_reports.md) submitted by your users.                                                                                        |
| Deploy Keys       | Create instance-wide [SSH deploy keys](../../ssh/README.md#deploy-keys).                                                                                 |
| Service Templates | Create [service templates](../project/integrations/services_templates.md) for projects.                                                                   |
| Labels            | Create and maintain [labels](labels.md) for your GitLab instance.                                                                                        |
| Appearance        | Customize [GitLab's appearance](../../customization/index.md).                                                                                           |
| Settings          | Modify the [settings](settings/index.md) for your GitLab instance.                                                                                       |

## Admin Dashboard

The Dashboard provides statistics and system information about the GitLab instance.

To access the Dashboard, either:

- Click the Admin Area icon (the wrench icon).
- Visit `/admin` on your self-managed instance.

The Dashboard is the default view of the Admin Area, and is made up of the following sections:

| Section    | Description   |
|------------|---------------|
| Projects   | The total number of projects, up to 10 of the latest projects, and the option of creating a new project. |
| Users      | The total number of users, up to 10 of the latest users, and the option of creating a new user. |
| Groups     | The total number of groups, up to 10 of the latest groups, and the option of creating a new group. |
| Statistics | Totals of all elements of the GitLab instance. |
| Features   | All features available on the GitLab instance. Enabled features are marked with a green circle icon, and disabled features are marked with a power icon. |
| Components | The major components of GitLab and the version number of each. A link to the Gitaly Servers is also included. |