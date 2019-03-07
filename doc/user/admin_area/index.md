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
| Overview          | View your GitLab Dashboard, and maintain projects, users, groups, jobs, runners, and Gitaly servers.                                                     |
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
