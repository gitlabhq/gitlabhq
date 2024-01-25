---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project integration administration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

NOTE:
This page contains administrator documentation for project integrations. For user documentation, see [Project integrations](../../user/project/integrations/index.md).

Project integrations can be configured and enabled by project administrators. As a GitLab instance
administrator, you can set default configuration parameters for a given integration that all projects
can inherit and use, enabling the integration for all projects that are not already using custom
settings.

You can update these default settings at any time, changing the settings used for all projects that
are set to use instance-level or group-level defaults. Updating the default settings also enables the integration
for all projects that didn't have it already enabled.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

## Manage instance-level default settings for a project integration

Prerequisites:

- You must have administrator access to the instance.

To manage instance-level default settings for a project integration:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Complete the fields.
1. Select **Save changes**.

WARNING:
This may affect all or most of the groups and projects on your GitLab instance. Review the details
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

If [group-level settings](../../user/project/integrations/index.md#manage-group-level-default-settings-for-a-project-integration) have also
been configured for the same integration, projects in that group inherit the group-level settings
instead of the instance-level settings.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Remove an instance-level default setting

Prerequisites:

- You must have administrator access to the instance.

To remove an instance-level default setting:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting an instance-level default setting removes the integration from all projects that have the integration set to use default settings.

### View projects that use custom settings

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218252) in GitLab 14.2.

Prerequisites:

- You must have administrator access to the instance.

To view projects in your instance that [use custom settings](../../user/project/integrations/index.md#use-custom-settings-for-a-project-or-group-integration):

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select the **Projects using custom settings** tab.
