---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project integration management **(FREE)**

Project integrations can be configured and enabled by project administrators. As a GitLab instance
administrator, you can set default configuration parameters for a given integration that all projects
can inherit and use, enabling the integration for all projects that are not already using custom
settings.

You can update these default settings at any time, changing the settings used for all projects that
are set to use instance-level or group-level defaults. Updating the default settings also enables the integration
for all projects that didn't have it already enabled.

Only the complete settings for an integration can be inherited. Per-field inheritance is [planned](https://gitlab.com/groups/gitlab-org/-/epics/2137).

## Manage instance-level default settings for a project integration **(FREE SELF)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2137) in GitLab 13.3 for project-level integrations.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2543) in GitLab 13.6 for group-level integrations.

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Integrations**.
1. Select an integration.
1. Enter configuration details and click **Save changes**.

WARNING:
This may affect all or most of the groups and projects on your GitLab instance. Please review the details
below.

If this is the first time you are setting up instance-level settings for an integration:

- The integration is enabled for all groups and projects that don't already have this integration configured,
  if you have the **Enable integration** toggle turned on in the instance-level settings.
- Groups and projects that already have the integration configured are not affected, but can choose to use the
  inherited settings at any time.

When you make further changes to the instance defaults:

- They are immediately applied to all groups and projects that have the integration set to use default settings.
- They are immediately applied to newer groups and projects, created after you last saved defaults for the
  integration. If your instance-level default setting has the **Enable integration** toggle turned
  on, the integration is automatically enabled for all such groups and projects.
- Groups and projects with custom settings selected for the integration are not immediately affected and may
  choose to use the latest defaults at any time.

Only the complete settings for an integration can be inherited. Per-field inheritance
is [planned](https://gitlab.com/groups/gitlab-org/-/epics/2137). This would allow
administrators to update settings inherited by groups and projects without enabling the
integration on all non-configured groups and projects by default.

### Remove an instance-level default setting

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > Integrations**.
1. Select an integration.
1. Click **Reset** and confirm.

Resetting an instance-level default setting removes the integration from all projects that have the integration set to use default settings.

## Manage group-level default settings for a project integration

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2543) in GitLab 13.6.

1. Navigate to the group's **Settings > Integrations**.
1. Select an integration.
1. Enter configuration details and click **Save changes**.

WARNING:
This may affect all or most of the subgroups and projects belonging to the group. Please review the details below.

If this is the first time you are setting up group-level settings for an integration:

- The integration is enabled for all subgroups and projects belonging to the group that don't already have
  this integration configured, if you have the **Enable integration** toggle turned on in the group-level
  settings.
- Subgroups and projects that already have the integration configured are not affected, but can choose to use
  the inherited settings at any time.

When you make further changes to the group defaults:

- They are immediately applied to all subgroups and projects belonging to the group that have the integration
  set to use default settings.
- They are immediately applied to newer subgroups and projects, even those created after you last saved defaults for the
  integration. If your group-level default setting has the **Enable integration** toggle turned on,
  the integration is automatically enabled for all such subgroups and projects.

- Subgroups and projects with custom settings selected for the integration are not immediately affected and
  may choose to use the latest defaults at any time.

Only the complete settings for an integration can be inherited. Per-field inheritance
is [planned](https://gitlab.com/groups/gitlab-org/-/epics/2137). This would allow
administrators to update settings inherited by subgroups and projects without enabling the
integration on all non-configured groups and projects by default.

### Remove a group-level default setting

1. Navigate to the group's **Settings > Integrations**.
1. Select an integration.
1. Click **Reset** and confirm.

Resetting a group-level default setting removes integrations that use default settings and belong to a project or subgroup of the group.

## Use instance-level or group-level default settings for a project integration

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2543) in GitLab 13.6 for group-level settings.

1. Navigate to **Project > Settings > Integrations**.
1. Choose the integration you want to enable or update.
1. From the drop-down, select **Use default settings**.
1. Ensure the toggle is set to **Enable integration**.
1. Click **Save changes**.

## Use custom settings for a group or project integration

1. Navigate to project or group's **Settings > Integrations**.
1. Choose the integration you want to enable or update.
1. From the drop-down, select **Use custom settings**.
1. Ensure the toggle is set to **Enable integration** and enter all required settings.
1. Click **Save changes**.
