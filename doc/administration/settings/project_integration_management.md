---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project integration management **(FREE SELF)**

Project integrations can be configured and enabled by project administrators. As a GitLab instance
administrator, you can set default configuration parameters for a given integration that all projects
can inherit and use, enabling the integration for all projects that are not already using custom
settings.

You can update these default settings at any time, changing the settings used for all projects that
are set to use instance-level or group-level defaults. Updating the default settings also enables the integration
for all projects that didn't have it already enabled.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

## Manage instance-level default settings for a project integration **(FREE SELF)**

To manage instance-level default settings for a project integration:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
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

If [group-level settings](#manage-group-level-default-settings-for-a-project-integration) have also
been configured for the same integration, projects in that group inherit the group-level settings
instead of the instance-level settings.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Remove an instance-level default setting

To remove an instance-level default setting:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting an instance-level default setting removes the integration from all projects that have the integration set to use default settings.

### View projects that use custom settings

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218252) in GitLab 14.2.

To view projects in your instance that [use custom settings](#use-custom-settings-for-a-project-or-group-integration):

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select the **Projects using custom settings** tab.

## Manage group-level default settings for a project integration

To manage group-level default settings for a project integration:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Complete the fields.
1. Select **Save changes**.

WARNING:
This may affect all or most of the subgroups and projects belonging to the group. Review the details below.

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

If [instance-level settings](#manage-instance-level-default-settings-for-a-project-integration)
have also been configured for the same integration, projects in the group inherit settings from the group.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/epics/2137).

### Remove a group-level default setting

To remove a group-level default setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting a group-level default setting removes integrations that use default settings and belong to a project or subgroup of the group.

## Use instance-level or group-level default settings for a project integration

To use instance-level or group-level default settings for a project integration:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select an integration.
1. On the right, from the dropdown list, select **Use default settings**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Complete the fields.
1. Select **Save changes**.

## Use custom settings for a project or group integration

To use custom settings for a project or group integration:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Integrations**.
1. Select an integration.
1. On the right, from the dropdown list, select **Use custom settings**.
1. Under **Enable integration**, ensure the **Active** checkbox is selected.
1. Complete the fields.
1. Select **Save changes**.
