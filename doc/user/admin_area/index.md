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
| Overview          | View your GitLab [Dashboard](#admin-dashboard), and administer [projects](#administer-projects), users, groups, jobs, runners, and Gitaly servers. |
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

## Administer Projects

You can administer all projects in the GitLab instance from the Admin Area's Projects page.

To access the Projects page, go to **Admin Area > Overview > Projects**.

Click the **All**, **Private**, **Internal**, or **Public** tab to list only projects of that
criteria.

By default, all projects are listed, in reverse order of when they were last updated. For each
project, the name, namespace, description, and size is listed, also options to **Edit** or
**Delete** it.

Sort projects by **Name**, **Last created**, **Oldest created**, **Last updated**, **Oldest
updated**, **Owner**, and choose to hide or show archived projects.

In the **Filter by name** field, type the project name you want to find, and GitLab will filter
them as you type.

Select from the **Namespace** dropdown to filter only projects in that namespace.

You can combine the filter options. For example, click the **Public** tab, and enter `score` in
the **Filter by name...** input box to list only public projects with `score` in their name.