---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Integration administration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

NOTE:
This page contains administrator documentation for project and group integrations. For user documentation, see [Project integrations](../../user/project/integrations/_index.md).

Project and group administrators can configure and enable integrations.
As an instance administrator, you can:

- Set default configuration parameters for an integration.
- Configure an allowlist to control which integrations can be enabled on a GitLab instance.

## Configure default settings for an integration

Prerequisites:

- You must have administrator access to the instance.

To configure default settings for an integration:

1. On the left sidebar, at the bottom, select **Admin**.
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

If [group-level settings](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) have also
been configured for the same integration, projects in that group inherit the group-level settings
instead of the instance-level settings.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Remove default settings for an integration

Prerequisites:

- You must have administrator access to the instance.

To remove default settings for an integration:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting an instance-level default setting removes the integration from all projects that have the integration set to use default settings.

### View projects that use custom settings

Prerequisites:

- You must have administrator access to the instance.

To view projects in your instance that [use custom settings](../../user/project/integrations/_index.md#use-custom-settings-for-a-project-or-group-integration):

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select the **Projects using custom settings** tab.

## Integration allowlist

DETAILS:
**Tier:** Ultimate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) in GitLab 17.7.

By default, project and group administrators can enable integrations.
However, instance administrators can configure an allowlist to control
which integrations can be enabled on a GitLab instance.

Enabled integrations that are later blocked by the allowlist settings are disabled.
If these integrations are allowed again, they are re-enabled with their existing configuration.

If you configure an empty allowlist, no integrations are allowed on the instance.
After you configure an allowlist, new GitLab integrations are not on the allowlist by default.

### Allow some integrations

Prerequisites:

- You must have administrator access to the instance.

To allow only integrations on the allowlist:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Integration settings** section.
1. Select **Allow only integrations on this allowlist**.
1. Select the checkbox for each integration you want to allow on the instance.
1. Select **Save changes**.

### Allow all integrations

Prerequisites:

- You must have administrator access to the instance.

To allow all integrations on a GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Integration settings** section.
1. Select **Allow all integrations**.
1. Select **Save changes**.
